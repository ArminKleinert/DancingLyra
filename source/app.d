import std.stdio;

import lyra.types;
import lyra.reader;
import lyra.eval;

void main() {
  import std.conv : to;

  auto test = make_ast(
      tokenize("[] [1 2 3] 1 -2 0.5 () #t #f \"abc\" sym1 (list) '(5 6 7) 'abc '1 '"));
  while (!test.isNil) {
    writeln(to!string(test.car) ~ " " ~ to!string(test.car.type));
    test = test.cdr;
  }

  Env env = new Env(null);
  writeln(eval(obj(1L), env));
  writeln(evalList(list(obj(1L), obj(2L), obj(3L)), env));
  writeln(evalKeepLast(list(obj(1L), obj(2L), obj(3L)), env));

  env.set(symbol("s"), obj(16L));
  writeln(env.toString());
  writeln(env.find(symbol("s")));
  Env envChild = new Env(env);
  envChild.set(symbol("s1"), obj(18L));
  writeln(envChild.toString());
  writeln(envChild.find(symbol("s1")));
  writeln(envChild.find(symbol("s")));
  writeln(envChild.find(symbol("a")));

  // auto id = new LyraFunc(name, env, list(symbol("e")), list(symbol("e")));
}
