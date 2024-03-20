buildImage () {
    docker build -t evmonecoverage .
    exit 0
}

rebuildImage () {
    docker build --no-cache -t evmonecoverage .
    exit 0
}

printHelp() {
    echo "Usage \"./dcoverage.sh --base=testsA --patch=testsB --test_type=GeneralStateTests\""
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
        --test_type=*)  # Match --patch="file"
            testType="${1#*=}" # Extract the value part of the argument
            shift 1         # Move to the next argument
            ;;
        --onlypatch)  # Match the --verbose option
            onlypatch=1  # Set the flag to 1 (on)
            shift
            ;;
        --testrepo)
            testrepo=1
            shift
            ;;
        *)          # Match any other argument
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done


testpath=$(pwd)/coverage
if [[ -z "$base" || -z "$patch" || -z "$testType" ]]; then
    if [ $testrepo -eq 0 ]; then
        echo "Error: Missing options!"
        printHelp
    else
        argstring="/tests/evmone_coverage.sh covertests /tests/tests $testType TESTREPO /tests"
        docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring
        user=$(whoami)
        sudo chown -R $user:$user $testpath
        exit 0
    fi
fi


if [ $onlypatch -eq 1 ]; then
    dirs=("PATCH_TESTS" "DIFF" "PATCH")
    for dir in "${dirs[@]}"; do
        dirpath="$testpath/$dir"
        rm -rf "$dirpath"
        mkdir -p "$dirpath"
    done
    cp $patch/* $testpath/PATCH_TESTS
else
    dirs=("BASE_TESTS" "PATCH_TESTS" "DIFF" "BASE" "PATCH")
    for dir in "${dirs[@]}"; do
        dirpath="$testpath/$dir"
        rm -rf "$dirpath"
        mkdir -p "$dirpath"
    done
    cp $base/* $testpath/BASE_TESTS
    cp $patch/* $testpath/PATCH_TESTS

    argstring="/tests/evmone_coverage.sh cover /tests/BASE_TESTS $testType BASE /tests"
    docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring
fi

argstring="/tests/evmone_coverage.sh cover /tests/PATCH_TESTS $testType PATCH /tests"
docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring

argstring="/tests/evmone_coverage.sh diff coverage_PATCH.lcov coverage_BASE.lcov /tests"
docker run --entrypoint /bin/bash -v $testpath:/tests evmonecoverage $argstring

if [ $onlypatch -eq 0 ]; then
    rm -r $testpath/BASE_TESTS
fi
rm -r $testpath/PATCH_TESTS

user=$(whoami)
sudo chown -R $user:$user $testpath
