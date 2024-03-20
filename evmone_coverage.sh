#!/bin/bash

MOD=$1
BUILD="/evmone/build"
CAPTURE_FLAGS="--ignore-errors mismatch  --exclude=\"$HOME/.hunter/*\" --exclude=\"$PWD/_deps/*\"  --exclude=\"11\" --exclude=\"statetest\"	--exclude=\"t8n\"	--exclude=\"unittests\" --exclude=\"utils\""

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

if [ $MOD == "cover" ];
then
    TESTS=$2
    TESTS_TYPE=$3
    OUTNAME=$4
    RESULT_FOLDER=$5


    cmd="retesteth -t $TESTS_TYPE -- --testfile $TESTS --clients evmone --testpath /dev/null"
    echo "$cmd"
    eval "$cmd"
    
    capturecover
fi

if [ $MOD == "covertests" ];
then
    TESTS=$2
    TESTS_TYPE=$3
    OUTNAME=$4
    RESULT_FOLDER=$5

    cmd="retesteth -t $TESTS_TYPE -- --clients evmone --testpath $TESTS"
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
