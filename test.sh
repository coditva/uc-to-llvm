#!/bin/sh

testdir="tests"
binary="./uc"
exitcode=0

function run_test() {
    err=0
    rm -f a.ll a.bc

    $binary "$testdir/$1" 1>/dev/null 2>&1
    err+=$?

    llvm-as a.ll 1>/dev/null 2>&1
    err+=$?

    lli a.bc 1>/dev/null 2>&1

    if [ $err -eq 0 ]; then
        echo "[PASS] $1"
    else
        echo "[FAIL] $1"
        exitcode=1
    fi
}

if [[ $TEST != "" ]]; then
    run_test $TEST
    exit $exitcode
fi

for testfile in $(ls $testdir) ; do
    run_test $testfile
done

exit $exitcode
