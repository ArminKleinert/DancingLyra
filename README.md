# Lyra

A dynamically typed Lisp written in D and mostly in itself.  
It started as a port of a language written in Ruby, but became its own thing by now.

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
  - Annoying bugs with variadic functions fixed.
  - Renamed `eql?` to `eq?`
  - Many tests
  - Support for different types of vectors
  - Support for a maybe type
  - Easy macros for defining new types
  - Now supports very limited modules
  - Basic file-IO (read/write/append/remove/exists?) and console-input (readln!) added

## Usage

Currently, there is not much to run here, but if you want to play with it, try the following.  

A script `compile.sh` is provided for compiling. For compiling and running, do  
```./compile.sh && ./app```  

In my tests, ldc with -O3 (in file `./compile2.sh`) was 30% faster, but took 50% longer to compile.

## Bugs


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
eq?            | 2     | Compares 2 objects
               |       | 
null?          | 1     | Check whether the value is an nil.
               |       | a vector.
int?           | 1     | Check whether the value is an int.
float?         | 1     | Check whether the value is an float.
bool?          | 1     | Check whether the value is a boolean.
string?        | 1     | Check whether the value is a string.
list?          | 1     | Check whether the value is a list.
cons?          | 1     | Check whether the value is a cons.
vector?        | 1     | Check whether the value is a vector.
eq?            | 2     | Check for equality of two objects.
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
foldl1         | 2     | 
foldr          | 3     | (Not implemented)
filter         | 2     | Filter a collection by predicate.
               |       | 
first          | 1     | 
second         | 1     | 
third          | 1     | 
rest           | 2     | 
set-at         | 2     | 
               |       | 
size           | 1     | 
empty?         | 1     | 
nth            | 2     | 
append         | 2     | 
find-first     | 2     | 
               |       | 
->vector       | 1     | 
->list         | 1     | 
copy           | 1     | 
but-last       | 1     | 
reverse        | 1     | 
map-while      | 3     | 
map-until      | 3     | 
take           | 2     | 
drop           | 2     | 
take-while     | 3     | 
take-until     | 3     | 
drop-while     | 3     | 
drop-until     | 3     | 
zip            | 2     | 
               |       | 
any?           | 2     | 
all?           | 2     | 
none?          | 2     | 
               |       | 
maybe          | 1     | 
nothing        | -     | 
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

To create a function which can have different behaviours on different types, Lyra provides `def-generic`. The function needs to be implemented using `def-method`:

```
; Creates a new function available in the calling module.
; Its inner behaviour performs a lookup depending on the type of the object. 
; (def-generic object (signature) fallback)

; Creates a new function using define: (define (signature) body)
; The function is then registered under `global-name` for the type `type-id`.
; The registered function is available inside the module which called 
; def-generic for this function.
; (def-method type-id global-name (signature) &body)

; Example:

; Template for a function which gets the first element from an object x.
; If the type of x does not have an implementation for `first`, 
; (nothing x) is called instead, returning an empty `maybe` object.
(def-generic x (first x) nothing)

; Actual implementations of first for the lists and vectors.
(def-method cons-id first (list-first x) (maybe (car x)))
(def-method vector-id first (vector-first x) (vector-get x 0))

; An example of why def-generic needs the object name:
; Without the name x, the function get confused on which variable's type to use.
; By convention, the implementation should depend on the 3rd parameter, but Lyra
; cannot know this without being told this once.
(def-generic x (foldl f e x)
  ...)
 
; To use existing functions, add-type-fns! can be used.
; This way, no additional functions are created.
(add-type-fns! cons-id
  (list (list 'first car)
        (list '->list id)))
```

Attention: NEVER USE ANY OF THESE INSIDE A LOOP!  
This would lead to a lot of overhead and may lead to other problems.

If possible, you should prefer specialized functions right away. 
The lookup takes time and a lot of it. It is much quicker to use a 
specialized version, but generic function are pretty to read at least.
This is one of the areas where a lot of potential for optimization waits...  

In short: For performance, you should use `vector-get` rather than `nth`.

Another possible way that generic function help is in hiding specific types. 
Internally, there might be dozens of versions of vectors, but to the
user, all of them should just be "vector". For example, appending vectors
would be slow, so an instance of `vector-pair` is created. Taking only the 
first n-5 elements of a vector would be slow, so Lyra creates an `offset-vector`
instead. To the user though, all of them can use `vector-get`, `vector-iterate`
and so on, even though their implementations may be different.  
By using `add-type-fns!`, the function which do not need a new implementation
can just be copied:

`(add-type-fns! vector-pair-id (list (list 'copy id) (list 'vector always-true)))`

## User-defined types

For the creation of new types, Lyra provides `register-type!` and `define-record`:

```
(let ((pair-id (register-type!)) ; pair-id now holds the id of a new type.
  ; Creates a type called "pair" with the id saved in pair-id with 2 members: x and y
  (define-record pair-id pair x y)
  
  ; 3 new functions are now created using an implicit define:
  ; (make-pair x y)
  ; (pair-x p)
  ; (pair-y p)
  
  (let ((p (make-pair 8 '()))
    (println! (pair-x p)) ; -> 8
    (println! (pair-y p))) ; -> ()
  
  ; No ->string function is created, but can be easily implemented:
  (def-method pair-id ->string (pair-to-string p)
    (string "(" (pair-x p) ", " (pair-y) ")"))
  
  (println! (make-pair 9 1)) ; -> (9, 1)
)
```

Attention: NEVER CREATE A TYPE INSIDE A LOOP OR FUNCTION!  
This would lead to lots of types being created. The system can only handle so many until it collapses.
