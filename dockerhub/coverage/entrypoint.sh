#!/bin/bash

BUILD="/evmone/build"
RESULT_FOLDER="/tests"
CAPTURE_FLAGS="--ignore-errors mismatch  --exclude=\"$HOME/.hunter/*\" --exclude=\"$PWD/_deps/*\" --exclude=\"11\" --exclude=\"unittests\" --exclude=\"utils\""

printHelp() {
    echo "Usage:"
    echo "Take the tests from --testpath and construct coverage report and data into --outputname file and folder:"
    echo "./entrtypoint.sh --mode=cover --testpath=/tests/BASE_TESTS --outputname=BASE"
    echo "./entrtypoint.sh --mode=cover --testpath=/tests/PATCH_TESTS --outputname=PATCH"

    echo "Take results from files and construct coverage diff report into DIFF folder:"
    echo "./entrtypoint.sh --mode=diff --basefile=coverage_BASE.lcov --patchfile=coverage_PATCH.lcov"

    echo ""
    echo "With --driver=retesteth (default) only:"
    echo "./entrtypoint.sh --mode=covertests --testtype=GeneralStateTests/stExample"
    exit 0
}

testtype="AUTO"
driver="retesteth"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode=*)        # cover | covertests | diff
            mode="${1#*=}"
            shift 1
            ;;
        --testpath=*)   # path to .json filled tests
            testpath="${1#*=}"
            shift 1
            ;;
        --driver=*)     # retesteth | native
            driver="${1#*=}"
            shift 1
            ;;
        --testtype=*)     # retesteth -t <testtype> argument | AUTO
            testtype="${1#*=}"
            shift 1
            ;;
        --outputname=*)   # filename to save to coverage results 
            outputname="${1#*=}"
            shift 1
            ;;
        --basefile=*)   # .lcov file to diff as a base
            basefile="${1#*=}"
            shift 1
            ;;
        --patchfile=*)   # .lcov file to diff as a patch
            patchfile="${1#*=}"
            shift 1
            ;;
        *)
            echo "Unknown option: $1"
            printHelp
            exit 1
            ;;
    esac
done
if [[ -z "$mode" ]]; then
    echo "Missing option: --mode"
    printHelp
    exit 1
fi

capturecover() {
    cmd="lcov --capture --directory $BUILD --output-file $BUILD/coverage.lcov $CAPTURE_FLAGS"
    echo "$cmd"
    eval "$cmd"

    cmd="lcov --zerocounters --directory $BUILD"
    echo "$cmd"
    eval "$cmd"

    cmd="genhtml $BUILD/coverage.lcov --output-directory $RESULT_FOLDER/$outputname --title \"${outputname}_COVERAGE\""
    echo "$cmd"
    eval "$cmd"

    cmd="cp $BUILD/coverage.lcov $RESULT_FOLDER/coverage_${outputname}.lcov"
    echo "$cmd"
    eval "$cmd"
}

sorttests() {
    # Directory containing the files
    DIR=$testpath

    # Subdirectories for classification
    DIR_BC="${DIR}/BC"
    DIR_ST="${DIR}/ST"
    DIR_EF="${DIR}/EF"

    # Create the subdirectories if they don't already exist
    mkdir -p "$DIR_BC"
    mkdir -p "$DIR_ST"
    mkdir -p "$DIR_EF"

    # Iterate over files in the directory
    for file in "$DIR"/*; do
         # Skip if the item is not a file
        if [ ! -f "$file" ]; then
            continue
        fi
        if grep -q "genesis" "$file"; then
            # If file contains "genesis", move it to BC
            mv "$file" "$DIR_BC/"
        elif grep -q "currentCoinbase" "$file"; then
            mv "$file" "$DIR_ST/"
        else
            mv "$file" "$DIR_EF/"
        fi
    done
}

if [ $mode == "cover" ];
then
    if [[ -z "$testpath" ]]; then
        echo "Missing option: --testpath"
        printHelp
        exit 1
    fi
    if [[ -z "$outputname" ]]; then
        echo "Missing option: --outputname"
        printHelp
        exit 1
    fi
    if [[ "$testtype" == "AUTO" ]]; then
        sorttests
        if [[ "$driver" == "retesteth" ]]; then
            cmd="retesteth -t GeneralStateTests -- --testfile $testpath/ST --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"
            cmd="retesteth -t BlockchainTests -- --testfile $testpath/BC --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"
            cmd="retesteth -t EOFTests -- --testfile $testpath/EF --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"
        fi
        if [[ "$driver" == "native" ]]; then
            cmd="evmone-statetest $testpath/ST"
            echo "$cmd"
            eval "$cmd"
            cmd="evmone-blockchaintest $testpath/BC"
            echo "$cmd"
            eval "$cmd"
            cmd="evmone-eoftest $testpath/EF"
            echo "$cmd"
            eval "$cmd"
        fi
    else
        if [[ "$driver" == "retesteth" ]]; then
            cmd="retesteth -t $testtype -- --testfile $testpath --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"
        fi
        if [[ "$driver" == "native" ]]; then
            sorttests
            cmd="evmone-statetest $testpath/ST"
            echo "$cmd"
            eval "$cmd"
            cmd="evmone-blockchaintest $testpath/BC"
            echo "$cmd"
            eval "$cmd"
            cmd="evmone-eoftest $testpath/EF"
            echo "$cmd"
            eval "$cmd"
        fi
    fi
    capturecover
fi

if [ $mode == "covertests" ];
then
    if [[ -z "$testpath" ]]; then
        echo "Missing option: --testpath"
        printHelp
        exit 1
    fi
    if [[ -z "$outputname" ]]; then
        echo "Missing option: --outputname"
        printHelp
        exit 1
    fi
    cmd="retesteth -t $testtype -- --clients evmone -j6 --testpath $testpath"
    echo "$cmd"
    eval "$cmd"

    capturecover
fi

if [ $mode == "diff" ];
then
    if [[ -z "$patchfile" ]]; then
        echo "Missing option: --patchfile"
        printHelp
        exit 1
    fi
    if [[ -z "$basefile" ]]; then
        echo "Missing option: --basefile"
        printHelp
        exit 1
    fi
    cmd="genhtml $RESULT_FOLDER/$patchfile --baseline-file $RESULT_FOLDER/$basefile --output-directory $RESULT_FOLDER/DIFF --title DIFF_COVERAGE"
    echo "$cmd"
    difflog=$($cmd)
    echo "$difflog" > "$RESULT_FOLDER/difflog.txt"
    echo "$difflog"
fi

#find . -name "*.gcda" -o -name "*.gcno" -exec rm -f {} +

