#!/bin/bash

MOD=$1
BUILD="/evmone/build"

if [ $MOD == "cover" ];
then
    TESTS=$2
    TESTS_TYPE=$3
    OUTNAME=$4
    RESULT_FOLDER=$5

    retesteth -t $TESTS_TYPE -- --testfile $TESTS --clients evmone --testpath /dev/null
    lcov --capture --directory $BUILD --output-file $BUILD/coverage.lcov --ignore-errors mismatch  --exclude="$HOME/.hunter/*" --exclude="$PWD/_deps/*"  --exclude="11" --exclude="state" --exclude="statetest"	--exclude="t8n"	--exclude="unittests" --exclude="utils"
    lcov --zerocounters --directory $BUILD
    genhtml $BUILD/coverage.lcov --output-directory $RESULT_FOLDER/$OUTNAME --title $OUTNAME_COVERAGE
    cp $BUILD/coverage.lcov $RESULT_FOLDER/coverage_$OUT.lcov
fi

if [ $MOD == "diff" ];
then
    FILE1=$2
    FILE2=$3
    RESULT_FOLDER=$4
    genhtml $RESULT_FOLDER/$FILE1 --baseline-file $RESULT_FOLDER/$FILE2 --output-directory $RESULT_FOLDER/DIFF --title DIFF_COVERAGE
fi


#find . -name "*.gcda" -o -name "*.gcno" -exec rm -f {} +
