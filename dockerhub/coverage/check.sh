#!/bin/bash
# ===================
# CHECK LOST COVERAGE
# ===================
findDigitFromReport(){
    lines=$1
    str=$2
    digit=$(echo "$lines" | grep -oP "$str.*?: \K\d+") 
    if [[ -z $digit ]];then
        digit="0"
    fi
    return $digit
}

difflog=$(cat "/tests/difflog.txt")
coverageInfo=$(echo "$difflog" | awk '/Overall coverage rate:/,0')
linesInfo=$(echo "$coverageInfo" | awk  '/lines/{flag=1} flag && !/functions/; /functions/{flag=0}')
functionsInfo=$(echo "$coverageInfo" | awk '/functions/,0')

echo ""
echo "==============="
echo "COVERAGE REPORT"
echo "/tests/DIFF/index.html"

findDigitFromReport "$linesInfo" "GBC"
echo "New covered Lines: $?"
findDigitFromReport "$linesInfo" "LBC"
LBC_LINES=$?

findDigitFromReport "$functionsInfo" "GBC"
echo "New covered function Paths: $?"
findDigitFromReport "$functionsInfo" "LBC"
LBC_FUNC=$?


if [ "$LBC_LINES" != "0" ] || [ "$LBC_FUNC" != "0" ]; then
    echo ""
    echo "ERROR: coverage is lost!"
    echo "Lost coverage Lines: $LBC_LINES"
    echo "Lost coverage function Paths: $LBC_FUNC"
    exit 1
else
    echo ""
    echo "RESULT: OK!"
    echo "No coverage was lost"
    exit 0
fi
