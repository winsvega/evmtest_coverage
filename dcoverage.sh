#!/bin/bash

buildImage () {
    docker build -t evmonecoverage .
    exit 0
}

rebuildImage () {
    docker build --no-cache -t evmonecoverage .
    exit 0
}

printHelp() {
    echo "Usage:"
    echo "./dcoverage.sh --base=testsA --patch=testsB [--driver=retesteth|native]"
    echo "./dcoverage.sh --base=file.lcov --patch=testsB"
    echo "./dcoverage.sh --base=file.lcov --patch=fileb.lcov"
    echo ""
    echo "With --driver=retesteth (default) only:"
    echo "./dcoverage.sh --testrepo --test_type=GeneralStateTests/stExample"
    exit 0
}

cleanDocker () {
    # Ask user a confirmation
    read -p "This will clean all docker containers and docker system, do you want to proceed? (y|n) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        docker rmi evmonecoverage:latest
        docker image rm evmonecoverage
        docker image prune -a -f
        docker container prune -f
        docker volume prune -f
        docker image rm evmonecoverage
        docker rmi evmonecoverage:latest
        docker system prune -f
    fi
    exit 0
}

case $1 in
    "build")
        buildImage
        ;;
    "rebuild")
        rebuildImage
        ;;
    "clean")
        cleanDocker
        ;;
esac


base=""
patch=""
testType=""
onlypatch=0
testrepo=0
driver="retesteth"

# Loop through all the arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --base=*)   # Match --base="file"
            base="${1#*=}"  # Extract the value part of the argument
            shift 1         # Move to the next argument
            ;;
        --patch=*)  # Match --patch="file"
            patch="${1#*=}" # Extract the value part of the argument
            shift 1         # Move to the next argument
            ;;
        --test_type=*)  # -t argument (GeneralStateTests or a specific test suite)
            testType="${1#*=}"
            shift 1
            ;;
        --driver=*)
            driver="${1#*=}"
            shift 1
            ;;
        --onlypatch)  # Do not recalculate the BASE
            onlypatch=1
            shift
            ;;
        --testrepo)
            testrepo=1
            shift
            ;;
        *)          # Match any other argument
            echo "Unknown option: $1"
            printHelp
            exit 1
            ;;
    esac
done

testType="AUTO"
testpath=$(pwd)/coverage
if [[ -z "$base" || -z "$patch" ]]; then
    if [ $testrepo -eq 0 ]; then
        echo "Error: Missing options!"
        printHelp
    else
        if [[ -z "$testType" ]]; then
            echo "Error: Missing options!"
            printHelp
        fi
        argstring="/tests/evmone_coverage.sh covertests /tests/tests $driver $testType TESTREPO /tests"
        docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring
        user=$(whoami)
        sudo chown -R $user:$user $testpath
        exit 0
    fi
fi
if [[ "$driver" != "retesteth" ]] && [[ "$driver" != "native" ]]; then
        echo "Error: Unknown driver! Supported: --driver=retesteth|native"
        printHelp
fi


if [[ -n "$patch" ]] && [[ "$patch" != *.lcov ]]; then
    dirs=("PATCH_TESTS" "PATCH_TESTS/BC" "PATCH_TESTS/ST" "DIFF" "PATCH")
    for dir in "${dirs[@]}"; do
        dirpath="$testpath/$dir"
        rm -rf "$dirpath"
        mkdir -p "$dirpath"
    done
    cp $patch/* $testpath/PATCH_TESTS

    argstring="/tests/evmone_coverage.sh cover /tests/PATCH_TESTS $driver $testType PATCH /tests"
    docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring
fi

if [[ -n "$base" ]] && [[ "$base" != *.lcov ]] && [[ "$onlypatch" != 1 ]]; then
    dirs=("BASE_TESTS" "BASE_TESTS/BC" "BASE_TESTS/ST" "DIFF" "BASE")
    for dir in "${dirs[@]}"; do
        dirpath="$testpath/$dir"
        rm -rf "$dirpath"
        mkdir -p "$dirpath"
    done
    cp $base/* $testpath/BASE_TESTS
    cp $patch/* $testpath/PATCH_TESTS

    argstring="/tests/evmone_coverage.sh cover /tests/BASE_TESTS $driver $testType BASE /tests"
    docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring
fi


basecoverfile="coverage_BASE.lcov"
if [[ "$base" == *.lcov ]]; then
    basecoverfile=$base
fi
patchcoverfile="coverage_PATCH.lcov"
if [[ "$patch" == *.lcov ]]; then
    patchcoverfile=$patch
fi

argstring="/tests/evmone_coverage.sh diff $patchcoverfile $basecoverfile /tests"
difflog=$(docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring)


if [[ -n "$patch" ]] && [[ "$patch" != *.lcov ]]; then
    rm -r $testpath/PATCH_TESTS
fi
if [[ -n "$base" ]] && [[ "$base" != *.lcov ]] && [[ "$onlypatch" != 1 ]]; then
    rm -r $testpath/BASE_TESTS
fi

user=$(whoami)
sudo chown -R $user:$user $testpath

echo "$difflog" > "./coverage/difflog.txt"
echo "$difflog"
