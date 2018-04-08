#!/bin/sh

testdir="samples"
binary="./uc"
exitcode=0

for testfile in $(ls $testdir) ; do

    $binary < $testdir/$testfile 1>/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "[PASS] $testfile"
    else
        echo "[FAIL] $testfile"
        exitcode=1
    fi
done

exit $exitcode
