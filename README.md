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
  - Optional lazy evaluation via. lazy type

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
inc            | 1     | Increases a number by 1.
dec            | 1     | Decreases a number by 1.
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
begin          | 2     | Run two expressions and return the result of the second.
               |       | 
empty?         | 1     | Check whether a collection is empty.
               |       | 
load!          | 1     | Load a Lyra file and execute it.
require!       | 1     | Alias for load!
import!        | 1     | Alias for load!
               |       | 
map            | 2     | Apply a function to each element of a list and return the
               |       | new list.
foldl          | 3     | 
foldl1         | 2     | 
foldr          | 3     | 
filter         | 2     | Filter a collection by predicate.
remove         | 2     | Like filter but with the predicate negated.
               |       | 
first          | 1     | Returns the first object of a sequence as a maybe.
second         | 1     | Returns the second object of a sequence as a maybe.
third          | 1     | Returns the third object of a sequence as a maybe.
rest           | 1     | Returns all but the first elements of a sequence.
set-at         | 2     | 
               |       | 
size           | 1     | Returns the size of a collection.
empty?         | 1     | Checks whether a collection is empty. (Also true for nil)
nth            | 2     | Returns the nth element of a sequential as a maybe object
               |       | `(nth '(1 2 3) 1) => 2`
append         | 2     | Appends two collections. The type of the result is that of 
               |       | the first operant.
find-first     | 2     | Find the first element in a collection for which the 
               |       | predicate p is true. `(find-first odd? '(2 3 4)) => 3`
               |       | 
->vector       | 1     | Turns a collection into a vector. Objects for whom `vector?` 
               |       | returns true are turned into a real vector too. Objects that 
               |       | cannot be turned into a vector become (maybe nothing)
->list         | 1     | Turns a collection into a list. The same rules apply as for
               |       | ->vector, but nil (empty list) is not changed.
copy           | 1     | Copies an object. The only type for which this does anything 
               |       | is box.
but-last       | 1     | Returns the first n-1 elements of a sequential collection.
reverse        | 1     | Reverses a sequential collection.
map-while      | 3     | 
map-until      | 3     | 
take           | 2     | 
drop           | 2     | 
take-while     | 3     | 
take-until     | 3     | 
drop-while     | 3     | 
drop-until     | 3     | 
zip            | 2     | Creates pairs of the entries of 2 sequences: 
               |       | `(zip '(1 2 3) '(4 5)) => ((1 4) (2 5))`
               |       | 
any?           | 2     | Checks whether a predicate holds true for any element in 
               |       | a list. `(any? odd? '(2 3 4)) => #t`
all?           | 2     | Checks whether a predicate holds true for all in a list.
none?          | 2     | Same as any? with the predicate negated.
               |       | 
maybe          | 1     | Creates an instance of maybe.
nothing        | -     | Takes any number of arguments and returns `(maybe nothing)`
               |       | 
lazy           | 2     | Takes a function and an object and stores them. Calling
               |       | lazy on a function and another lazy object stores the
               |       | function without executing.
eager          | 1     | Takes a object of the lazy type and executes it.
               |       | 
null?          | 1     | Checks for the empty list.
symbol?        | 1     | 
string?        | 1     | 
char?          | 1     | 
integer?       | 1     | 
real?          | 1     | 
cons?          | 1     | 
list?          | 1     | 
vector?        | 1     | 
func?          | 1     | 
bool?          | 1     | 
boolean?       | 1     | 
box?           | 1     | 
maybe?         | 1     | 
nothing?       | 1     | 
lazy?          | 1     | Checks whether an object is an instance of lazy.
partial?       | 1     | Checks whether an object is a partial function application.
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

### maybe something, maybe nothing

Some functions might return something, some might not. For example, `first` returns the first element of a sequence, but what should it return for an empty sequence? What is the first element of an empty list?  
That's why all functions that get the nth element of a sequence or access a collection via a key or similar return a maybe. The result can be unpacked using the `unpack` function or the postfix `.?`:  
```
(define (head l) (if (null? l) (maybe (car l) (nothing))))
(head '(1 2 3))              => (maybe 1)
(head '())                   => (maybe nothing)
(let* (e (head '(1 2))) e)   => (maybe 1)
(head '(1 2 3)).?            => 1
(head '()).?                 => nothing
(let* (e (head '(1 2))) e.?) => 1
```

### Lazyness / Selective participation

Lazyness currently has to be done explicitly and can be evaluated using the function `eager` or the postfix `.!`:  
```
(lazy inc 1) => (lazy (inc) 1)
(lazy inc (lazy dec 1)) => (lazy (inc dec) 1)
(lazy even? (lazy inc (lazy second [1 2 3])))
  => (lazy (even? inc second) [1 2 3])

(lazy inc 1).! => 2

(lazy even? (lazy inc (lazy second [1 2 3]))).! => #f
  ; (even? (inc (second [1 2 3])))
  ; (even? (inc 2))
  ; (even? 3)
  ; #f
```

### Different functions on different types

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

`(add-type-fns! vector-pair-id (list (list 'copy id) (list 'vector? always-true)))`

### User-defined types

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
    (string "(" (pair-x p) ", " (pair-y p) ")"))
  
  (println! (make-pair 9 1)) ; -> (9, 1)
)
```

Attention: NEVER CREATE A TYPE INSIDE A LOOP OR FUNCTION!  
This would lead to lots of types being created. The system can only handle so many until it collapses.
