## Micro C (*uC)* to *LLVM* compiler
Micro C or *uC* is a subset of C language. This compiler compiles it to
*LLVM* for execution.

### How to
Make sure you have *LLVM* library installed before compiling
```bash
make        # compile
make test   # run tests
make clean  # cleanup
TEST=test0.uc make test  # run tests on test0.uc only

./uc FILENAME   # generate the LLVM IR
llvm-as a.ll    # convert the IR to bytecode
lli a.bc        # run the bytecode
```
The IR generated can be found in `a.ll` and the byte-code is in `a.bc`.

### About *uC*
The *uC* is a subset of C with very basic functionality. The implemented
version of *uC* supports the following:

- All variable are of type `int32`.
- Every statement ends with `;`.
- Variable can be assigned as: `a = 10;` or `a = b;` given `b` is defined before
- Arguments can be input as `a = $1;`.
- There are _no_ functions. Everything is assumed to be in `main`.
- Comments start with `//` and go on till end of line.
- `if (condition) { statements }`
- `if (condition) { statements } else { statements }`
- `while (condition) { statments }`
- `for (expression; condition; expression) { statements }`
- `do { statements } while (condition);`
- If there is only one statement, `{` and `}` can be dropped.
- Loops and conditional statements _cannot_ be nested.
- All operators from C are supported.
- `break` and `return` are supported.

See programs in `tests/` for sample.

### Author
Utkarsh Maheshwari

### License
MIT
