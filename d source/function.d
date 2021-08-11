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

class PartialFunc : LyraObj, LyraFunc {
    private LyraFunc f;
    private Vector args;

    static PartialFunc partial(LyraFunc f, Cons args) {
        return new PartialFunc(f, args);
    }

    private this(LyraFunc inner, Cons givenArgs) {
        this.f = inner;
        this.args = listToVector(givenArgs);
    }

    override LyraObj call(Cons args1, Env env) {
        foreach_reverse (x; args) {
            args1 = Cons.create(x, args1);
        }
        return f.call(args1, env);
    }

    nothrow Symbol getName() {
        return f.getName();
    }

    nothrow bool ispure() {
        return f.ispure();
    }

    nothrow bool isMacro() {
        return f.isMacro();
    }

    nothrow uint minArgs() {
        return f.minArgs() - cast(uint) args.length;
    }

    nothrow uint maxArgs() {
        return f.maxArgs() - cast(uint) args.length;
    }

    nothrow uint expectedType() {
        return f.expectedType();
    }

    nothrow override uint type() {
        return func_id;
    }
}

class NativeLyraFunc : ALyraFunc {
    private const LyraObj delegate(Cons, Env) fnBody;
    this(string name, uint minargs, uint maxargs, bool variadic, bool ispure,
            bool isMacro, LyraObj delegate(Cons, Env) fnBody) {
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

class NonNativeLyraFunc : ALyraFunc {
    private Env definitionEnv;
    private Cons argNames;
    private LyraObj bodyExpr;

    this(Symbol name, Env definitionEnv, uint argc, Cons argNames, LyraObj bodyExpr,
            bool variadic, bool ispure, bool isMacro) {
        super(name, argc, variadic ? uint.max : argc, variadic, isMacro, ispure, unknown_id);
        this.definitionEnv = definitionEnv;
        this.argNames = argNames;
        this.bodyExpr = bodyExpr;
    }

    override LyraObj call(Cons args, Env callEnv) {
        Env env = new Env(getName(), definitionEnv, definitionEnv, callEnv);
        LyraObj result;
        Cons argNames1;
        uint argcGiven;

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
