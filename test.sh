#!/bin/sh

testdir="samples"
binary="./uc"

for testfile in $(ls $testdir) ; do
    $binary < $testdir/$testfile 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "[PASS] $testfile"
    else
        echo "[FAIL] $testfile"
    fi
done
