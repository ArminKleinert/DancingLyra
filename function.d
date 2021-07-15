module lyrafunction;

//import std.conv;
import std.stdio;

import types;
import evaluate;

class NativeLyraFunc : LyraFunc {
    private const LyraObj delegate(Cons, Env) fnBody;

    this(string name, int minargs, int maxargs, bool variadic, LyraObj delegate(Cons, Env) fnBody) {
        super(name, minargs, maxargs, variadic, false);
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
            bool variadic = false, bool isMacro = false) {
        super(name, argc, variadic ? int.max : argc, variadic, isMacro);
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
            if (args.isNil)
                break;
            if (variadic && argNames1.cdr.isNil()) {
                env.set(argNames1.car, args);
                argcGiven += listSize(args);
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
