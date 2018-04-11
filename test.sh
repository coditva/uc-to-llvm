#!/bin/sh

testdir="tests"
binary="./uc"
exitcode=0
verbose=1

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

if [[ $TEST != "" ]]; then
    if [[ $(run_test $TEST) == 0 ]]; then
        echo "[PASS] $TEST"
        exitcode=0
    else
        echo "[FAIL] $TEST"
        exitcode=1
    fi
    exit $exitcode
fi

for testfile in $(ls $testdir) ; do
    verbose=0
    if [[ $(run_test $testfile) == 0 ]]; then
        echo "[PASS] $testfile"
    else
        echo "[FAIL] $testfile"
        exitcode=1
    fi
done

exit $exitcode
