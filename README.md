# evmtest_coverage
Docker that builds evmone in a coverage mode and an entry script that do the report

# Usage
```
./dcoverage.sh build      -   make a docker image
./dcoverage.sh rebuild    -   update docker image (after editing the Dockerfile)
./dcoverage.sh clean      -   remove all docker images and containers for sure (docker has issues removing the containers)
```

# Main command: make a coverage report of how many lines got covered (green), lost (red) into ./converted/DIFF/index.html folder
```
./dcoverage.sh --base=testsA --patch=testsB [--driver=retesteth|native]
./dcoverage.sh --base=file.lcov --patch=testsB
./dcoverage.sh --base=file.lcov --patch=fileb.lcov

With --driver=retesteth (default) only:
./dcoverage.sh --testrepo --test_type=GeneralStateTests/stExample

```
