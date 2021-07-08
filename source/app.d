import std.stdio;

import lyra.types;
import lyra.reader;

void main() {
  writeln(obj(15L));
  writeln(LyraObj.makeFixnum(19));
  writeln(list([obj(1L), obj(0.5), obj("abc")]));
  writeln(vector([]));
  writeln(vector([obj(1L)]));
  writeln(vector([obj(15L), obj(16L), obj(17L)]));

  import std.conv : to;

  auto test = make_ast(tokenize("1 -2 0.5 () #t #f \"abc\" sym1 (list)"));
  while (!test.isNil) {
    writeln(test.car.toString ~ " " ~ to!string(test.car.type));
    test = test.cdr;
  }
}
