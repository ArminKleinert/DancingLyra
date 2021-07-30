# Lyra

A port of https://github.com/ArminKleinert/Lyra from Ruby to D.  
My hope is that this will make for a big performance improvement and maybe 
help out with future projects where a statically typed language has to be 
used for implementing a dynamically typed language.  

Luckily, most functions were implemented in Lyra itself, lessening the 
workload of porting it.  

Development on this port will be slow because life is a thing.

## Goals and differences to Lyra

- Minimal set of native functions (math, streams, initialization)
- Having fun
- No functions that can mutate collections (No `set-car!` or `set-cdr!`)
- Testing some optimizations
  - Compilation
  - Interpretation
  - Functional collections

## Progress 
- 0.0.01
  - Implemented most needed types (fixnums, reals, strings, vectors, conses, functions, boxes)
  - Implemented some basic functions
  - Evaluation and definition of functions work now
  - Tail recursion works
  - Macros work now
  - Build in a stack limit which can be adjusted in the future
  - define for variables works
  - eval function gives warnings for invalid forms.
- 0.0.02
  - Functions can now be called with different behaviours for different types.
  - User-defined types are now available

## Usage

Currently, there is not much to run here, but if you want to play with it, try the following.  

A script `compile.sh` is provided for compiling. For compiling and running, do  
```./compile.sh && ./app```  

If you want to compile the files yourself, the order is the following:  
```dmd -O app.d types.d eval.d function.d reader.d buildins.d```  
If you are using a different compiler, just replace `dmd` with it.  
In my tests, ldc with -O3 was 30% faster, but took 50% longer to compile.

## Base instructions

`(define <name> <value>)` Define a global variable.  
`(define (<name <&arguments>) <&body>)` Define a new function at the global scope.  
`(def-macro (<name> <&arguments>) <&body>)` Define a new macro.  
`(lambda (<&arguments>) <&body>)` Define an anonymous function.   
`(quote <expression>)`  
`(if <condition> <then-branch> <else-branch>)` Classic if.  
`(cond <&condition-expression-pairs>)`   
`(let (<&bindings>) <&body>)` Create a new environment with 0 or more new variables.  
`(let* (<name> <value>) <&body>)` Create a new environment with 1 new variable.  
`(apply <function> <&expressions> <list>)`  

## Base types

- Integer
- Float
- String
- Cons (Also used for lists)
  - Nil (Empty list)
- Boolean
- Function
- Vector
- Box (the only type that can be mutated)

## Native functions

```
Name           | Arity | Description
---------------+-------+-------------------------------------------------------------
+              | 2     | Addition (numbers)
-              | 2     | Subtraction (numbers)
*              | 2     | Multiplication (numbers)
/              | 2     | Division (numbers)
%              | 2     | Modulo (numbers)
               |       | 
=              | 2     | Equality (atoms)
<              | 2     | Less than (numbers and strings)
>              | 2     | Greater than (numbers and strings)
<=             | 2     | Less than or equal (numbers and strings)
>=             | 2     | Greater than equal (numbers and strings)
               |       | 
cons           | 2     | Creates a new cons
_car           | 1     | Gets the car of a cons.
_cdr           | 1     | Gets the cdr of a cons.
               |       | 
vector         | any   | Returns its arguments as a vector.
_vector-get    | 2     | Returns an element from a vector.
_vector-set    | 3     | Sets an element of a vector without mutating.
_vector-append | 2     | Appends an element to a vector without mutating.
_vector-iterate| 2     | Quickly iterates a vector.
_vector-size   | 1     | Returns the size of a vector
               |       | 
int            | 1     | Returns a cons. The car is the converted element as an int. 
               |       | The cdr is an error message if the conversion failed. (Not implemented)
float          | 1     | Same as int but tries to convert to a float. (Not implemented)
string         | 1     | Returns the string representation of a variable.
bool           | 1     | Converts #f and '() into #f and anything else into #t. (Not implemented)
               |       | 
box            | 1     | Creates a new box. This type makes mutation possible.
unbox          | 1     | Returns the contents of a box.
box-set!       | 2     | Sets the contents of a box.
               |       | 
open!          | 2     | Opens a file stream. (Not implemented)
close!         | 1     | Closes a file stream. (Not implemented)
stream-seek!   | 2     | Set a stream to a given position. (Not implemented)
sread!         | 1     | Reads from a stream. (stdin or file) (Not implemented)
sprint!        | 2     | Writes to a stream. (stdout, stderr or file) (Not implemented)
slurp!         | 1     | Reads a whole file into string.
parse          | 1     | Parses a string into lyra types.
eval!          | 1     | Evaluates a piece of lyra using the compiler's internal
               |       | "eval" function.
               |       | 
lyra-type-id   | 1     | Returns the type id of its argument.
measure        | 2     | Measures the median time for n runs of a function f in milliseconds.
define-record  | 2     | Define a new type (Explained far below).
```

## Core library function

```
Name           | Arity | Description
---------------+-------+-------------------------------------------------------------
inc            | 1     |
dec            | 1     |
               |       | 
and            | 2     | Logic and
or             | 2     | Logic or
not            | 2     | Logic not
               |       | 
null?          | 1     | Check whether the value is an nil.
atom?          | 1     | Check whether the value is not a cons, not a string and not
               |       | a vector.
int?           | 1     | Check whether the value is an int.
float?         | 1     | Check whether the value is an float.
bool?          | 1     | Check whether the value is a boolean.
string?        | 1     | Check whether the value is a string.
list?          | 1     | Check whether the value is a list.
cons?          | 1     | Check whether the value is a cons.
vector?        | 1     | Check whether the value is a vector.
eql?           | 2     | Check for equality of two objects.
               |       | 
nth            | 2     | Get the nth element of a collection.
length         | 1     | Get the length of a collection.
               |       | 
begin          | 2     | Run two expressions and return the result of the second.
               |       | 
empty?         | 1     | Check whether a collection is empty.
               |       | 
load!          | 1     | Load a Lyra file and execute it.
require!       | 1     | Alias for load!
import!        | 1     | Alias for load!
               |       | 
map            | 2     | Apply a function to each element of a list and return the new
               |       | list.
foldl          | 3     | 
foldr          | 3     | 
filter         | 2     | Filter a collection by predicate.
               |       | 
println!       | 1     | 

// TODO: This list needs updating
```

## Examples

### Macros.

Some instructions like `and`, `or` and `begin` can (and should) be 
implemented as macros.

```
; If x and y are true, return true or false otherwise
(def-macro (and x y) (list 'if x y #f))
; If x is true, return true, otherwise return y
(def-macro (or x y) (list 'if x #t y))
; Run x and ignore the result. Then return y.
(def-macro (begin x y) (list 'if x y y))

(def-macro (not x) (list 'if x #f #t))

; For nand it is a bit less simple:
(def-macro (nand x y)
  (list 'if x (list 'not y) #f))
```

### Functions.

Here is a sample definition for `load!` and `foldl`.

```
; Read a file, parse it into lyra-types, evaluate and return the result.
(define (load! f)
  (eval! (parse (slurp! f))))

; Iterates a collection using tail-recursion
(define (foldl f init xs)
  (if (empty? xs)
    init
    (foldl f (f init (first xs)) (rest xs))))

; Example usage of foldl: Sum all the elements of a list.
(define (sum xs)
  (foldl + 0 xs))
```

## Different functions on different types

With `add-type-fn!`, the user can set a function's behaviour for a given type:
```
(add-type-fn! list-id 'empty? null?)
(add-type-fn! vector-id 'empty? (lambda (v) (= (vector-size v) 0)))
```

Lists and vectors now use different implementations for `empty?`. The `empty?` function itself should now be implemented as  
`(define (empty? c) ((find-type-fn c 'empty?) c))`  
Which means that `empty?` will do a lookup for an implementation for `empty?` for the type of `c`. If it is found, the function is called with `c` as its input.  

To define a function with a default behaviour (for example a type-checker), you can define it as
`(define (vector? e) (let* (f (find-type-fn e 'vector?)) (if f (f e) #f)))`  
This means that if the function `vector?` is defined for the type of `e`, that implementation is used. If it is not found, `#f` is returned as the default output.  

## User-defined types

To define a new type, Lyra provides the functions `add-type!`, `define-record`, `add-type-fn!` and `find-type-fn`.  
```
(define offset-vector-id (add-type!)) ; add-type! returns a new id

; This automatically generates the functions (offset-vector start end vec), (offset-vector? e), (offset-vector-start e), (offset-vector-end e) and (offset-vector-vec e)
(define-record offset-vector-id offset-vector start end vec)

; Example:
(let* (ov (offset-vector 1 3 [1 2 3 4 5 6]))
  (offset-vector? ov) ; -> #t
  (offset-vector-start ov) ; -> 1
  (offset-vector-end ov) ; -> 3
  (offset-vector-vec ov) ; -> [1 2 3 4 5 6]
  )

; Now we can define some new functions for this type:
(add-type-fn! offset-vector-id 'vector? (lambda (ov) #t)) ; An offset-vector is a vector

(add-type-fn! offset-vector-id 'empty?
  (lambda (ov) (and (= (offset-vector-start ov) 0) (= (offset-vector-end ov) 0))))

...
```
