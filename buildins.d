module buildins;

import types;
import lyrafunction;
import evaluate;

import std.stdio;

void initializeGlobalEnv(Env env) {
    void addFn(string name, int minargs, bool variadic, bool ispure,bool isMacro,
            LyraObj delegate(Cons, Env) fnBody) {
        auto maxargs = variadic ? int.max : minargs;
        env.set(symbol(name), new NativeLyraFunc(name, minargs, maxargs, variadic, ispure, isMacro, fnBody));
    }

    auto numbercode(string op) {
        return "auto arg0 = xs.car;
        auto arg1 = xs.cdr.car;
        if (arg0.type == fixnum_id) {
            if (arg1.type == fixnum_id) {
                return LyraObj.makeFixnum(arg0.fixnum_val " ~ op ~ " arg1.fixnum_val);
            } else if (arg1.type == real_id) {
                return LyraObj.makeReal(arg0.fixnum_val "
            ~ op ~ " arg1.real_val);
            } else {
                return nil();
            }
        } else if (arg0.type == real_id) {
            if (arg1.type == fixnum_id) {
                return LyraObj.makeReal(arg0.real_val " ~ op
            ~ " arg1.fixnum_val);
            } else if (arg1.type == real_id) {
                return LyraObj.makeReal(arg0.real_val " ~ op ~ " arg1.real_val);
            } else {
                return nil();
            }
        } else {
            return nil();
        }";
    }

    auto comparator(string op) {
        return "auto arg0 = xs.car;
        auto arg1 = xs.cdr.car;
        if (arg0.type == fixnum_id) {
            if (arg1.type == fixnum_id) {
                return LyraObj.makeBoolean(arg0.fixnum_val " ~ op ~ " arg1.fixnum_val);
            } else if (arg1.type == real_id) {
                return LyraObj.makeBoolean(arg0.fixnum_val "
            ~ op ~ " arg1.real_val);
            } else {
                return LyraObj.makeBoolean(false);
            }
        } else if (arg0.type == real_id) {
            if (arg1.type == fixnum_id) {
                return LyraObj.makeBoolean(arg0.real_val " ~ op ~ " arg1.fixnum_val);
            } else if (arg1.type == real_id) {
                return LyraObj.makeBoolean(arg0.real_val " ~ op ~ " arg1.real_val);
            } else {
                return LyraObj.makeBoolean(false);
            }
        } else if (arg0.type == string_id && arg1.type == string_id) {
            return LyraObj.makeBoolean(arg0.string_val "
            ~ op ~ " arg1.string_val);
        } else if (arg0.type == symbol_id && arg1.type == symbol_id) {
            return LyraObj.makeBoolean(arg0.symbol_val " ~ op ~ " arg1.symbol_val);
        } else if (arg0.type == char_id && arg1.type == char_id) {
            return LyraObj.makeBoolean(arg0.char_val " ~ op ~ " arg1.char_val);
        } else {
            return LyraObj.makeBoolean(arg0 " ~ op ~ " arg1);
        }";
    }

    addFn("+", 2, false, true, false,(xs, env) { mixin(numbercode("+")); });
    addFn("-", 2, false, true, false,(xs, env) { mixin(numbercode("-")); });
    addFn("*", 2, false, true, false,(xs, env) { mixin(numbercode("*")); });
    addFn("/", 2, false, true, false,(xs, env) { mixin(numbercode("/")); });
    addFn("=", 2, false, true, false,(xs, env) { mixin(comparator("==")); });
    addFn("<", 2, false, true, false,(xs, env) { mixin(comparator("<")); });
    addFn(">", 2, false, true, false,(xs, env) { mixin(comparator(">")); });
    addFn("<=", 2, false, true, false,(xs, env) { mixin(comparator("<=")); });
    addFn(">=", 2, false, true, false,(xs, env) { mixin(comparator(">=")); });

    addFn("&&", 2, true, true, true,(xs, env) {
        while (!xs.isNil()) {
            if (eval(xs.car, env).isFalsy()) {
                return LyraObj.makeBoolean(false);
            }
            xs = xs.next();
        }
        return LyraObj.makeBoolean(true);
    });
    
    addFn("||", 2, true, true, true,(xs, env) {
        while (!xs.isNil()) {
            if (!eval(xs.car, env).isFalsy()) {
                return LyraObj.makeBoolean(true);
            }
            xs = xs.next();
        }
        return LyraObj.makeBoolean(false);
    });

    addFn("cons", 2, false, true, false,(xs, env) { return cons(xs.car, xs.cdr.car); });
    addFn("_car", 1, false, true, false,(xs, env) {
        if (xs.car.type != cons_id) {
            throw new Exception("_car: Expected Cons.");
        }
        return xs.car.car;
    });
    addFn("_cdr", 1, false, true, false,(xs, env) {
        if (xs.car.type != cons_id) {
            throw new Exception("_cdr: Expected Cons.");
        }
        return xs.car.cdr;
    });

    addFn("vector", 0, true, true, false,(xs, env) { return vector(listToVector(xs)); });

    addFn("_vector-append", 2, false, true, false,(xs, env) {
        if (xs.car.type != vector_id) {
            throw new Exception("_vector-append: Expected vector.");
        }
        return vector(xs.car.vector_val ~ xs.cdr.car);
    });

    addFn("_vector-get", 2, false, true, false,(xs, env) {
        if (xs.car.type != vector_id || xs.cdr.car.type != fixnum_id) {
            throw new Exception("_vector-get: Expected vector and fixnum.");
        }
        return xs.car.vector_val[xs.cdr.car.fixnum_val];
    });

    addFn("_vector-size", 1, false, true, false,(xs, env) {
        if (xs.car.type != vector_id) {
            throw new Exception("_vector-size: Expected vector.");
        }
        return LyraObj.makeFixnum(xs.car.vector_val.length);
    });

    addFn("_vector-iterate", 3, false, true, false,(xs, env) {
        if (xs.car.type != vector_id || xs.cdr.cdr.car.type != func_id) {
            throw new Exception("_vector-iterate: Expected vector, then any, then function.");
        }
        auto vec = xs.car.vector_val;
        auto accumulator = xs.cdr.car;
        auto fn = xs.cdr.cdr.car.func_val;
        for (fixnum i = 0; i < vec.length; i++) {
            accumulator = fn.call(list(accumulator, vec[i], LyraObj.makeFixnum(i)), env);
        }
        return accumulator;
    });

    addFn("string", 0, true, true, false,(xs, env) {
        auto s = "";
        while (!xs.isNil()) {
            if (xs.car.type == string_id)
                s ~= xs.car.string_val;
            else
                s ~= xs.car.toString();
            xs = xs.next();
        }
        return LyraObj.makeString(s);
    });

    addFn("println!", 1, false, false,false, (xs, env) {
        if (xs.car.type == string_id)
            writeln(xs.car.string_val);
        else
            writeln(xs.car.toString());
        return Cons.nil();
    });

    addFn("box", 1, false, false, false,(xs, env) { return box(xs.car); });
    addFn("unbox", 1, false, false,false, (xs, env) { return unbox(xs.car); });
    addFn("box-set!", 2, false, false, false,(xs, env) {
        boxSet(xs.car, xs.cdr.car);
        return xs.cdr.car;
    });

    addFn("measure", 2, false, false, false,(xs, env) {
        auto median(long[] arr) {
            import std.algorithm.sorting;

            sort(arr);
            auto len = arr.length;
            return (arr[(len - 1) / 2] + arr[len / 2]) / 2;
        }

        import std.datetime.stopwatch;
        import core.time : Duration;

        auto times = xs.car.fixnum_val;
        auto fn = xs.cdr.car.func_val;
        auto args = Cons.nil();

        long[] drs = [];
        auto sw = StopWatch(AutoStart.no);

        for (; times > 0; times--) {
            sw.reset();
            sw.start();
            fn.call(args, env);
            sw.stop();
            drs ~= sw.peek().total!"nsecs";
        }

        return LyraObj.makeReal(median(drs) / 1000000000.0);
    });

    addFn("eval!", 1, false, false, false,(xs, env) { return evalKeepLast(xs.car, env); });
    addFn("parse", 1, false, false, false,(xs, env) {
        import reader;

        if (xs.car.type != string_id) {
            throw new Exception("parse: Expected string.");
        }
        return make_ast(tokenize(xs.car.value.string_val));
    });
    addFn("slurp!", 1, false, false, false,(xs, env) {
        import std.file : readText;

        if (xs.car.type != string_id) {
            throw new Exception("slurp!: Expected string.");
        }
        return LyraObj.makeString(readText(xs.car.value.string_val));
    });

    addFn("lyra-type-id", 1, false, true, false,(xs, env) { return xs.car.objtype(); });
}
