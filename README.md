# evmtest_coverage
Docker that builds evmone in a coverage mode and an entry script that do the report

# Usage
```
./dcoverage.sh build      -   make a docker image
./dcoverage.sh rebuild    -   update docker image (after editing the Dockerfile)
./dcoverage.sh clean      -   remove all docker images and containers for sure (docker has issues removing the containers)

# main command: make a coverage report of how many lines got covered (green), lost (red)
# by the testFolderPatch .json tests compared to testFolderBase .json test coverage
./dcoverage.sh testFolderBase  testFolderPatch GeneralStateTests
```
