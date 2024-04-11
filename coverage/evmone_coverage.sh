#!/bin/bash

MOD=$1
BUILD="/evmone/build"
CAPTURE_FLAGS="--ignore-errors mismatch  --exclude=\"$HOME/.hunter/*\" --exclude=\"$PWD/_deps/*\" --exclude=\"11\" --exclude=\"unittests\" --exclude=\"utils\""

capturecover() {
    cmd="lcov --capture --directory $BUILD --output-file $BUILD/coverage.lcov $CAPTURE_FLAGS"
    echo "$cmd"
    eval "$cmd"

    cmd="lcov --zerocounters --directory $BUILD"
    echo "$cmd"
    eval "$cmd"

    cmd="genhtml $BUILD/coverage.lcov --output-directory $RESULT_FOLDER/$OUTNAME --title \"${OUTNAME}_COVERAGE\""
    echo "$cmd"
    eval "$cmd"

    cmd="cp $BUILD/coverage.lcov $RESULT_FOLDER/coverage_${OUTNAME}.lcov"
    echo "$cmd"
    eval "$cmd"
}

sorttests() {
    # Directory containing the files
    DIR=$TESTS

    # Subdirectories for classification
    DIR_BC="${DIR}/BC"
    DIR_ST="${DIR}/ST"

    # Create the subdirectories if they don't already exist
    mkdir -p "$DIR_BC"
    mkdir -p "$DIR_ST"

    # Iterate over files in the directory
    for file in "$DIR"/*; do
         # Skip if the item is not a file
        if [ ! -f "$file" ]; then
            continue
        fi
        if grep -q "genesis" "$file"; then
            # If file contains "genesis", move it to BC
            mv "$file" "$DIR_BC/"
        else
            # Otherwise, move it to ST
            mv "$file" "$DIR_ST/"
        fi
    done
}

if [ $MOD == "cover" ];
then
    TESTS=$2
    DRIVER=$3
    TESTS_TYPE=$4
    OUTNAME=$5
    RESULT_FOLDER=$6

    if [[ "$TESTS_TYPE" == "AUTO" ]]; then
        sorttests
        if [[ "$DRIVER" == "retesteth" ]]; then
            cmd="retesteth -t GeneralStateTests -- --testfile $TESTS/ST --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"    
            cmd="retesteth -t BlockchainTests -- --testfile $TESTS/BC --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"    
        fi
        if [[ "$DRIVER" == "native" ]]; then
            cmd="evmone-statetest $TESTS/ST"
            echo "$cmd"
            eval "$cmd"    
            cmd="evmone-blockchaintest $TESTS/BC"
            echo "$cmd"
            eval "$cmd"    
        fi
    else
        if [[ "$DRIVER" == "retesteth" ]]; then
            cmd="retesteth -t $TESTS_TYPE -- --testfile $TESTS --clients evmone --testpath /dev/null"
            echo "$cmd"
            eval "$cmd"
        fi
        if [[ "$DRIVER" == "native" ]]; then
            sorttests
            cmd="evmone-statetest $TESTS/ST"
            echo "$cmd"
            eval "$cmd"    
            cmd="evmone-blockchaintest $TESTS/BC"
            echo "$cmd"
            eval "$cmd"    
        fi
    fi
    capturecover
fi

if [ $MOD == "covertests" ];
then
    TESTS=$2
    DRIVER=$3
    TESTS_TYPE=$4
    OUTNAME=$5
    RESULT_FOLDER=$6

    cmd="retesteth -t $TESTS_TYPE -- --clients evmone -j6 --testpath $TESTS"
    echo "$cmd"
    eval "$cmd"

    capturecover
fi

if [ $MOD == "diff" ];
then
    FILE1=$2
    FILE2=$3
    RESULT_FOLDER=$4
    cmd="genhtml $RESULT_FOLDER/$FILE1 --baseline-file $RESULT_FOLDER/$FILE2 --output-directory $RESULT_FOLDER/DIFF --title DIFF_COVERAGE"
    echo "$cmd"
    eval "$cmd"
fi

#find . -name "*.gcda" -o -name "*.gcno" -exec rm -f {} +
