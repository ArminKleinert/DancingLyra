module lyrafunction;

//import std.conv;
import std.stdio;

import types;
import evaluate;

private string itos(ulong e) {
    import std.conv;

    return to!string(e);
}

private string itos(int e) {
    import std.conv;

    return to!string(e);
}

class NativeLyraFunc : LyraFunc {
    private const LyraObj delegate(Cons, Env) fnBody;
    this(string name, int minargs, int maxargs, bool variadic, bool ispure, bool isMacro, LyraObj delegate(Cons, Env) fnBody) {
        super(name, minargs, maxargs, variadic, isMacro, ispure, unknown_id);
        this.fnBody = fnBody;

    }

    override LyraObj call(Cons args, Env callEnv) {
        size_t argc = listSize(args);
        if (argc < minargs || argc > maxargs) {
            throw new Exception("Wrong number of arguments for " ~ this.toString() ~ ". Expected " ~ itos(
                    minargs) ~ " to " ~ itos(maxargs) ~ " but got " ~ itos(argc));
        }
        return fnBody(args, callEnv);
    }
}

class NonNativeLyraFunc : LyraFunc {
    private Env definitionEnv;
    private Cons argNames;
    private LyraObj bodyExpr;

    this(Symbol name, Env definitionEnv, int argc, Cons argNames, LyraObj bodyExpr,
            bool variadic, bool ispure, bool isMacro) {
        super(name, argc, variadic ? int.max : argc, variadic, isMacro, ispure, unknown_id);
        this.definitionEnv = definitionEnv;
        this.argNames = argNames;
        this.bodyExpr = bodyExpr;
    }

    override LyraObj call(Cons args, Env callEnv) {
        Env env = new Env(definitionEnv, callEnv);
        LyraObj result;
        Cons argNames1;
        int argcGiven;

    start:

        argNames1 = argNames;
        argcGiven = 0;

        while (!argNames1.isNil) {

            if (variadic && argNames1.cdr.isNil()) {
                env.set(argNames1.car, args);
                argcGiven += listSize(args);
                break;
            } else if (args.isNil) {
                break;
            } else {
                argcGiven++;
                env.set(argNames1.car, args.car);
                argNames1 = argNames1.next;
                args = args.next;
            }
        }

        if (argcGiven < minargs || (!variadic && argcGiven > maxargs)) {
            throw new Exception("Wrong number of arguments for " ~ this.toString() ~ ". Expected " ~ itos(
                    minargs) ~ " to " ~ itos(maxargs) ~ " but got " ~ itos(argcGiven));
        }

        try {
            result = evalKeepLast(bodyExpr, env);
        } catch (TailCall tc) {
            args = tc.args;
            goto start; // Tail call
        } catch (LyraStackOverflow lso) {
            throw lso;
        } catch (Exception ex) {
            writeln(name ~ " failed with error " ~ ex.msg);
            writeln("Arguments: " ~ args.toString());
            throw ex;
        }

        return result;
    }
}

class TailCall : Exception {
    Cons args;
    this(Cons args, string msg = "", string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
        this.args = args;
    }
}
