import std.stdio;

import types;
import reader;
import evaluate;
import buildins;
import lyrafunction;

void main(string[] args) {
    import std.file : readText;

    initializeGlobalEnv(Env.globalEnv);

    for (auto i = 1; i < args.length; i++) {
        switch (args[i]) {
        case "-AllowRedefine":
            eval_AllowRedefine();
            args[i] = null;
            break;
        case "-NoTail":
            eval_DisallowTailRecursion();
            args[i] = null;
            break;
        default:
            break;
        }
    }

    auto code = make_ast(tokenize(readText("core.lyra")));
    writeln(evalKeepLast(code, Env.globalEnv));
    foreach (fname; args[1 .. $]) {
        if (fname is null)
            continue;
        code = make_ast(tokenize(readText(fname)));
        evalKeepLast(code, Env.globalEnv);
    }
}
