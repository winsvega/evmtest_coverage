buildImage () {
    docker build -t evmonecoverage .
    exit 0
}

rebuildImage () {
    docker build --no-cache -t evmonecoverage .
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

testA=$1
testB=$2
typeC=$3
testpath=$(pwd)/coverage

dirs=("BASE_TESTS" "PATCH_TESTS" "DIFF" "BASE" "PATCH")
for dir in "${dirs[@]}"; do
    dirpath="$testpath/$dir"
    rm -rf "$dirpath"
    mkdir -p "$dirpath"
done

cp $testA/* $testpath/BASE_TESTS
cp $testB/* $testpath/PATCH_TESTS
argstring="/tests/BASE_TESTS /tests/PATCH_TESTS /tests $typeC"
docker run -v $testpath:/tests evmonecoverage $argstring

rm -r $testpath/BASE_TESTS
rm -r $testpath/PATCH_TESTS

user=$(whoami)
sudo chown -R $user:$user $testpath
