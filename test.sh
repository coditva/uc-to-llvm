#!/bin/sh

testdir="tests"
binary="./uc"
exitcode=0

function run_test() {
    $binary < $testdir/$1 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
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
