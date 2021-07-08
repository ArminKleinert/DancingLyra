# Lyra

A port of https://github.com/ArminKleinert/Lyra from Ruby to D.  
My hope is that this will make for a big performance improvement and maybe help out with future projects where a statically typed language has to be used for implementing a dynamically typed language.  

Luckily, most functions were implemented in Lyra itself, lessening the workload of porting it.  

Development on this port will be slow because life is a thing.

## Base instructions

define
def-macro
lambda
quote
if
cond
let*
let
apply

## Native functions

```
Math operators for 2 numbers.
p+  | Addition
p-  | Subtraction
p*  | Multiplication
p/  | Division
p%  | Modulo

Bit-math operators for 2 integers.
p&  | Bitwise and
p|  | Bitwise or
p<< | Bitwise shift left
p>> | Bitwise shift right

Comparison operators for 2 atoms.
p=  | Equality
p<  | Less than
p>  | Greater than

Name           | Arity | Description
---------------+-------+---------------------
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

