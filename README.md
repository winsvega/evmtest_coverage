# evmtest_coverage
Docker that builds evmone in a coverage mode and an entry script that do the report

# Usage
```
./dcoverage.sh build      -   make a docker image
./dcoverage.sh rebuild    -   update docker image (after editing the Dockerfile)
./dcoverage.sh clean      -   remove all docker images and containers for sure (docker has issues removing the containers)
```

## Main command: make a coverage report of how many lines got covered (green), lost (red) into ./converted/DIFF/index.html folder
```
./dcoverage.sh --tests=./testsA --mode=cover --outputname=BASE  [--driver=retesteth|native]
./dcoverage.sh --tests=./testsB --mode=cover --outputname=PATCH [--driver=retesteth|native]
./dcoverage.sh --mode=diff --basefile=coverage_BASE.lcov --patchfile=coverage_PATCH.lcov
```
