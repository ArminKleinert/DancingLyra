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
p+             | 2     | Addition (numbers)
p-             | 2     | Subtraction (numbers)
p*             | 2     | Multiplication (numbers)
p/             | 2     | Division (numbers)
p%             | 2     | Modulo (numbers)
               |       | 
p&             | 2     | Bitwise and (integers)
p|             | 2     | Bitwise or (integers)
p<<            | 2     | Bitwise shift left (integers)
p>>            | 2     | Bitwise shift right (integers)
               |       | 
p=             | 2     | Equality (atoms)
p<             | 2     | Less than (numbers)
p>             | 2     | Greater than (numbers)
               |       | 
cons           | 2     | Creates a new cons
car            | 1     | Gets the car of a cons. Undefined for other types.
cdr            | 1     | Gets the cdr of a cons. Undefined for other types.
               |       | 
vector         | any   | Returns its arguments as a vector.
vector-nth     | 2     | Returns an element from a vector.
vector-set     | 3     | Sets an element of a vector without mutating.
vector-append  | 2     | Appends an element to a vector without mutating.
vector-iterate | 2     | Quickly iterates a vector.
vector-size    | 1     | Returns the size of a vector
               |       | 
int            | 1     | Returns a cons. The car is the converted element as an int. 
               |       | The cdr is an error message if the conversion failed. 
float          | 1     | Same as int but tries to convert to a float.
string         | 1     | Returns the string representation of a variable.
bool           | 1     | Converts #f and '() into #f and anything else into #t.
               |       | 
box            | 1     | Creates a new box. This type makes mutation possible.
unbox          | 1     | Returns the contents of a box.
box-set!       | 2     | Sets the contents of a box.
               |       | 
open!          | 2     | Opens a file stream.
close!         | 1     | Closes a file stream.
stream-seek!   | 2     | Set a stream to a given position.
sread!         | 1     | Reads from a stream. (stdin or file)
sprint!        | 2     | Writes to a stream. (stdout, stderr or file)
slurp!         | 1     | Reads a whole file into string.
parse          | 1     | Parses a string into lyra types.
eval!          | 1     | Evaluates a piece of lyra using the compiler's internal
               |       | "eval" function.
               |       | 
plist          | any   | Creates a new list but sets its type to the first parameter
               |       | (int). At least one parameter is required.
pcons          | 3     | Creates a new cons but sets its type to the first parameter
               |       | (int).
pvector        | any   | Creates a new vector but sets its type to the first parameter
               |       | (int). At least one parameter is required.
lyra-type-id   | 1     | Returns the type id of its argument.
```

## Core library function

```
Name           | Arity | Description
---------------+-------+-------------------------------------------------------------
+              | any   | Addition
-              | any   | Subtraction
*              | any   | Multiplication
/              | any   | Division
%              | any   | Modulo
inc            | 1     |
dec            | 1     |
               |       | 
&              | 2     | Bitwise and (integers)
|              | 2     | Bitwise or (integers)
<<             | 2     | Bitwise shift left (integers)
>>             | 2     | Bitwise shift right (integers)
               |       | 
=              | any   | Equality
<              | any   | Less than
<=             | any   | Less than or equal
>              | any   | Greater than
>=             | any   | Greater than or equal
               |       | 
and            | 2     | Logic and
or             | 2     | Logic or
not            | 2     | Logic not
               |       | 
nil?           | 1     | Check whether the value is an int.
atom?          | 1     | Check whether the value is not a cons, not a string and not
               |       | a vector.
int?           | 1     | Check whether the value is an int.
float?         | 1     | Check whether the value is an float.
bool?          | 1     | Check whether the value is a boolean.
string?        | 1     | Check whether the value is a string.
list?          | 1     | Check whether the value is a list.
cons?          | 1     | Check whether the value is a cons.
vector?        | 1     | Check whether the value is a vector.
               |       | 
nth            | 2     | Get the nth element of a collection.
first          | 1     | Get the first element of a collection.
second         | 1     | Get the second element of a collection.
third          | 1     | Get the third element of a collection.
rest           | 1     | Get all but the first element of a collection.
rrest          | 1     | Short for (rest (rest xs))
ffirst         | 1     | Short for (first (first xs)
sfirst         | 1     | Short for (second (first xs)
rfirst         | 1     | Short for (rest (first xs)
length         | 1     | Get the length of a collection
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
foldr          | 3     | 
filter         | 2     | Filter a collection by predicate.
               |       | 
print!         | 1     | 
println!       | 1     | 
```

## Examples


