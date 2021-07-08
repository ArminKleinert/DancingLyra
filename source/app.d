import std.stdio;

import lyra.types;
import lyra.reader;

void main() {
    auto tokens = tokenize("(define (f s n) (cons s n)) (f \"abc\" -3)");
    writeln(tokens);
    LyraObj o = make_ast(tokens);
    writeln(o.type);
    writeln(cons_id);
    writeln(o);

    writeln(list([obj(1), obj(0.5), obj("abc")]));
}
