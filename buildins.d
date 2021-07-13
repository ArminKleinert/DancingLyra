module buildins;

import types;
import lyrafunction;

import std.stdio;

void initializeGlobalEnv(Env env) {
    void addFn(string name, int minargs, bool variadic, LyraObj delegate(Cons, Env) fnBody) {
        env.set(symbol(name), new NativeLyraFunc(name, minargs, minargs, variadic, fnBody));
    }
    
    auto numbercode(string op){
    return "auto arg0 = xs.car;auto arg1 = xs.cdr.car;
      if (arg0.type == fixnum_id){
        if (arg1.type == fixnum_id){
          return LyraObj.makeFixnum(arg0.fixnum_val "~op~" arg1.fixnum_val);
        }else if (arg1.type == real_id){
          return LyraObj.makeReal(arg0.fixnum_val "~op~" arg1.real_val);
        }else{ return nil();}
        }else if (arg0.type == real_id){
        if (arg1.type == fixnum_id){
          return LyraObj.makeReal(arg0.real_val "~op~" arg1.fixnum_val);
        }else  if (arg1.type == real_id){
          return LyraObj.makeReal(arg0.real_val "~op~" arg1.real_val);
        }else {return nil();}
        }else {return nil();}";
    }

    addFn("+", 2, false, (xs, env) {
        mixin(numbercode("+"));
    });
    addFn("-", 2, false, (xs, env) {
        mixin(numbercode("-"));
    });
    addFn("*", 2, false, (xs, env) {
        mixin(numbercode("*"));
    });
    addFn("/", 2, false, (xs, env) {
        mixin(numbercode("/"));
    });
}
