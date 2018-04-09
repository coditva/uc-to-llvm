## Micro C (uC) to LLVM compiler
Micro C or uC is a subset of C language. This compiler compiles it to
LLVM for execution.

### How to
Make sure you have LLVM library installed before compiling
```bash
make        # compile
make test   # run tests
make clean  # cleanup
TEST=test0.uc make test  # run tests on test0.uc only
```

### Author
Utkarsh Maheshwari
