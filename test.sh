#!/bin/sh

testdir="tests"
binary="./uc"
exitcode=0
verbose=1

RED='\033[0;31m'
GRN='\033[0;32m'
NOC='\033[0m'


function run_test() {
    rm -f a.ll a.bc

    if [[ $verbose == 0 ]]; then $binary "$testdir/$1" 1>/dev/null 2>&1
    else $binary "$testdir/$1"; fi
    if [[ $? != 0 ]]; then echo 1; fi

    if [[ $verbose == 0 ]]; then llvm-as a.ll 1>/dev/null 2>&1
    else llvm-as a.ll; fi
    if [[ $? != 0 ]]; then echo 1; fi

    echo 0
}

if [[ $TEST != "" ]];
then tests=$TEST
else tests=$(ls $testdir); verbose=0
fi

for testfile in $tests ; do
    if [[ $(run_test $testfile) == 0 ]]; then
        echo -e "${GRN}[PASS]${NOC} $testfile"
    else
        echo -e "${RED}[FAIL]${NOC} $testfile"
        exitcode=1
    fi
done

exit $exitcode
