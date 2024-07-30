#!/bin/bash

buildImage () {
    cd ./dockerhub/coverage
    docker build -t evmone-coverage-script .
    exit 0
}

rebuildImage () {
    cd ./dockerhub/coverage
    docker build --no-cache -t evmone-coverage-script .
    exit 0
}

printHelp() {
    echo "Usage:"
    echo "./dcoverage.sh --tests=./testsA --mode=cover --outputname=BASE  [--driver=retesteth|native]"
    echo "./dcoverage.sh --tests=./testsB --mode=cover --outputname=PATCH [--driver=retesteth|native]"
    echo "./dcoverage.sh --mode=diff --basefile=coverage_BASE.lcov --patchfile=coverage_PATCH.lcov"
#    echo ""
#    echo "With --driver=retesteth (default) only:"
#    echo "./dcoverage.sh --testrepo --test_type=GeneralStateTests/stExample"
    exit 0
}

cleanDocker () {
    # Ask user a confirmation
    read -p "This will clean all docker containers and docker system, do you want to proceed? (y|n) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        docker rmi evmone-coverage-script:latest
        docker image rm evmone-coverage-script
        docker image prune -a -f
        docker container prune -f
        docker volume prune -f
        docker image rm evmone-coverage-script
        docker rmi evmone-coverage-script:latest
        docker system prune -f
        docker system prune -a --volumes
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

testpath=$(pwd)/coverage
MOUNT="-v $testpath:/tests"
user=$(whoami)
sudo chown -R $user:$user $testpath

driver="retesteth"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --driver=*)        # retesteth | native
            driver="${1#*=}"
            shift 1
            ;;
        --mode=*)        # cover | covertests | diff
            mode="${1#*=}"
            shift 1
            ;;
        --tests=*)       # path to the folder with tests
            tests="${1#*=}"
            shift 1
            ;;
        --basefile=*)
            basefile="${1#*=}"
            shift 1
            ;;
        --patchfile=*)
            patchfile="${1#*=}"
            shift 1
            ;;
        --outputname=*)   # filename to save to coverage results 
            outputname="${1#*=}"
            shift 1
            ;;
        *)
            echo "Unknown option: $1"
            printHelp
            exit 1
            ;;
    esac
done

if [[ -z "$outputname" || -z "$mode" || -z "$tests" ]]; then
    if [[ -z "$basefile" || -z "$patchfile" ]]; then
        echo "Missing options, read help:"
        printHelp
        exit 1
    fi
fi


if [ -d "${testpath}/${outputname}_TESTS" -a ! -z "$outputname" ]; then
    rm -r "${testpath}/${outputname}"
    rm -r "${testpath}/${outputname}_TESTS"
    rm "${testpath}/coverage_${outputname}.lcov"
fi
if [ -n "$outputname" ]; then
    mkdir "${testpath}/${outputname}_TESTS"
fi


if [[ "$mode" == "cover" ]]; then
    cp -r $tests/* "${testpath}/${outputname}_TESTS"
    docker run $MOUNT evmone-coverage-script --mode=$mode --driver=$driver --testpath=/tests/${outputname}_TESTS --outputname=${outputname}
fi
if [[ "$mode" == "diff" ]]; then
    rm -r "${testpath}/DIFF"
    rm "${testpath}/difflog.txt"
    docker run $MOUNT evmone-coverage-script --mode=$mode --basefile=$basefile --patchfile=$patchfile
    docker run $MOUNT -it --entrypoint=./check.sh evmone-coverage-script
fi


sudo chown -R $user:$user $testpath
