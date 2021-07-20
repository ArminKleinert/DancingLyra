module buildins;

import types;
import lyrafunction;

import std.stdio;

void initializeGlobalEnv(Env env) {
    void addFn(string name, int minargs, bool variadic, bool ispure, LyraObj delegate(Cons, Env) fnBody) {
        auto maxargs = variadic ? int.max : minargs;
        env.set(symbol(name), new NativeLyraFunc(name, minargs, maxargs, variadic, ispure, fnBody));
    }

    auto numbercode(string op) {
        return "auto arg0 = xs.car;auto arg1 = xs.cdr.car;
      if (arg0.type == fixnum_id){
        if (arg1.type == fixnum_id){
          return LyraObj.makeFixnum(arg0.fixnum_val " ~ op ~ " arg1.fixnum_val);
        }else if (arg1.type == real_id){
          return LyraObj.makeReal(arg0.fixnum_val "
            ~ op ~ " arg1.real_val);
        }else{ return nil();}
        }else if (arg0.type == real_id){
        if (arg1.type == fixnum_id){
          return LyraObj.makeReal(arg0.real_val " ~ op
            ~ " arg1.fixnum_val);
        }else  if (arg1.type == real_id){
          return LyraObj.makeReal(arg0.real_val " ~ op ~ " arg1.real_val);
        }else {return nil();}
        }else {return nil();}";
    }

    auto comparator(string op) {
        return "auto arg0 = xs.car;auto arg1 = xs.cdr.car;
      if (arg0.type == fixnum_id){
        if (arg1.type == fixnum_id){
          return LyraObj.makeBoolean(arg0.fixnum_val " ~ op
            ~ " arg1.fixnum_val);
        }else if (arg1.type == real_id){
          return LyraObj.makeBoolean(arg0.fixnum_val " ~ op ~ " arg1.real_val);
        }else{ return LyraObj.makeBoolean(false); }
        }else if (arg0.type == real_id){
        if (arg1.type == fixnum_id){
          return LyraObj.makeBoolean(arg0.real_val " ~ op ~ " arg1.fixnum_val);
        }else  if (arg1.type == real_id){
          return LyraObj.makeBoolean(arg0.real_val "
            ~ op ~ " arg1.real_val);
        }else {return LyraObj.makeBoolean(false);}
        }else if (arg0.type == string_id && arg1.type == string_id) {
        return LyraObj.makeBoolean(arg0.string_val " ~ op ~ " arg1.string_val);
        }else if (arg0.type == symbol_id && arg1.type == symbol_id) {
        return LyraObj.makeBoolean(arg0.symbol_val " ~ op
            ~ " arg1.symbol_val);
        }else if (arg0.type == vector_id && arg1.type == vector_id) {
        return LyraObj.makeBoolean(arg0.vector_val " ~ op ~ "arg1.vector_val);
        }else{ return LyraObj.makeBoolean(arg0 == arg1); }";
    }

    addFn("+", 2, false, true, (xs, env) { mixin(numbercode("+")); });
    addFn("-", 2, false, true, (xs, env) { mixin(numbercode("-")); });
    addFn("*", 2, false, true, (xs, env) { mixin(numbercode("*")); });
    addFn("/", 2, false, true, (xs, env) { mixin(numbercode("/")); });
    addFn("=", 2, false, true, (xs, env) { mixin(comparator("==")); });
    addFn("<", 2, false, true, (xs, env) { mixin(comparator("<")); });
    addFn(">", 2, false, true, (xs, env) { mixin(comparator(">")); });
    addFn("<=", 2, false, true, (xs, env) { mixin(comparator("<=")); });
    addFn(">=", 2, false, true, (xs, env) { mixin(comparator(">=")); });

    addFn("cons", 2, false, true, (xs, env) { return cons(xs.car, xs.cdr.car); });
    addFn("_car", 1, false, true, (xs, env) { return xs.car.car; });
    addFn("_cdr", 1, false, true, (xs, env) { return xs.car.cdr; });
    //addFn("list", 0, true, (xs, env) { return xs; });

    addFn("vector", 0, true, true, (xs, env) { return vector(listToVector(xs)); });

    addFn("_vector-append", 2, false, true, (xs, env) {
        if (xs.car.type != vector_id) {
            throw new Exception("Expected vector.");
        }
        return vector(xs.car.vector_val ~ xs.cdr.car);
    });

    addFn("_vector-get", 2, false, true, (xs, env) {
        if (xs.car.type != vector_id || xs.cdr.car.type != fixnum_id) {
            throw new Exception("Expected vector and fixnum.");
        }
        return xs.car.vector_val[xs.cdr.car.fixnum_val];
    });

    addFn("_vector-size", 1, false, true, (xs, env) {
        if (xs.car.type != vector_id) {
            throw new Exception("Expected vector.");
        }
        return LyraObj.makeFixnum(xs.car.vector_val.length);
    });

    addFn("println!", 1, false, false, (xs, env) { writeln(xs.car); return Cons.nil(); });
    addFn("measure", 2, false, false, (xs, env) {
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
}
