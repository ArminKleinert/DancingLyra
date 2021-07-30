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
        case "-O":
            eval_DoOptimize();
            args[i] = null;
            break;
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

    /*
    LyraRecord.create(15, "vector-pair", Env.globalEnv(),
            true, ["a","b"]);
    writeln(Env.globalEnv().toStringWithoutParents());
    
    auto testcode = "(vector-pair 1 2)";
    auto code = make_ast(tokenize(testcode));
    
    auto lr = evalKeepLast(code,  Env.globalEnv());
    
    testcode = "vector-pair-a";
    code = make_ast(tokenize(testcode));
    auto a = evalKeepLast(code, Env.globalEnv());
    writeln(a.toString());
    writeln(evalKeepLast(list(list(a, lr)), Env.globalEnv()));
    
    testcode = "vector-pair-b";
    code = make_ast(tokenize(testcode));
    writeln(evalKeepLast(code, Env.globalEnv()));
    
    testcode = "(vector-pair-a (vector-pair 1 2 ))";
    code = make_ast(tokenize(testcode));
    writeln(evalKeepLast(code, Env.globalEnv()));
    
    testcode = "(vector-pair-b (vector-pair 1 2 ))";
    code = make_ast(tokenize(testcode));
    writeln(evalKeepLast(code, Env.globalEnv()));
    */

    auto code = make_ast(tokenize(readText("core.lyra")));
    evalKeepLast(code, Env.globalEnv);
    foreach (fname; args[1 .. $]) {
        if (fname is null)
            continue;
        code = make_ast(tokenize(readText(fname)));
        evalKeepLast(code, Env.globalEnv);
    }
}
