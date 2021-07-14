module evaluate;

import std.stdio;
import types;
import lyrafunction;

private LyraFunc[] callStack = [null];

Cons evalList(LyraObj exprList, Env env) {
    Vector v = [];
    while (!exprList.isNil) {
        v ~= eval(exprList.car, env, true);
        exprList = exprList.next();
    }
    return list(v);
}

LyraObj evalVector(LyraObj expr, Env env) {
    Vector v = vector_val(expr);
    for (auto i = 0; i < v.length; i++)
        v[i] = eval(v[i], env, true);
    return vector(v);
}

LyraObj evalKeepLast(LyraObj exprList, Env env, bool disableTailCall = false) {
    if (exprList.isNil())
        return exprList;
    while (!(exprList.cdr.isNil)) {
        eval(exprList.car, env, true);
        exprList = exprList.next();
    }
    return eval(exprList.car, env, disableTailCall);
}

LyraObj evDefine(LyraObj expr, Env env, bool isMacro) {
    auto name = expr.car.car;
    expr = cons(expr.car.cdr, expr.cdr); // Remove name
    auto func = evLambda(expr, env, name.symbol_val, isMacro);
    Env.globalEnv.set(name, func);
    return func;
}

LyraObj evLambda(LyraObj expr, Env env, Symbol name = "", bool isMacro = false) {
    // TODO Check type of bindings
    auto argNames = expr.car.cons_val;
    auto bodyExpr = expr.next;

    auto argVector = listToVector(argNames);
    auto variadic = argVector.length > 1 && argVector[1].symbol_val == "&";

    return new NonNativeLyraFunc(name, env, argNames, bodyExpr, variadic, isMacro);
}

LyraObj eval(LyraObj expr, Env env, bool disableTailCall = false) {
start:

    if (expr.type == cons_id) {
        if (expr.car.type == symbol_id) {
            switch (expr.car.symbol_val) {
            case "quote":
                return expr.cdr.car;
            case "define":
                return evDefine(expr.cdr, env, false);
            case "def-macro":
                return evDefine(expr.cdr, env, true);
            case "let":
                expr = expr.cdr;
                LyraObj bindings = expr.car;
                env = new Env(env);
                while (!bindings.isNil) {
                    // TODO Error check here
                    LyraObj sym = bindings.car.car;
                    LyraObj val = bindings.car.cdr.car;
                    env.set(sym, val);
                    bindings = bindings.cdr;
                }
                return evalKeepLast(expr.cdr, env, disableTailCall);
            case "let*":
                expr = expr.cdr;
                LyraObj binding = expr.car;
                env = new Env(env);
                // TODO Error check here
                LyraObj sym = binding.car;
                LyraObj val = eval(binding.cdr.car, env, true);
                env.set(sym, val);
                auto res = evalKeepLast(expr.cdr, env, disableTailCall);
                return res;
            case "lambda":
                return evLambda(expr.cdr, env);
            case "if":
                // TODO Arity check here
                expr = expr.cdr;
                LyraObj condition = eval(expr.car, env, true);
                expr = expr.cdr;
                if (condition.isNil || (condition.type == bool_id && condition.bool_val == true)) {
                    return eval(expr.car, env, disableTailCall);
                } else {
                    return eval(expr.cdr.car, env, disableTailCall);
                }
            case "cond":
                // TODO
                return nil();
            case "apply":
                // TODO
                return nil();
            default:
                expr = cons(env.find(expr.car), expr.cdr);
                goto start;
            }
        } else if (expr.car.type == cons_id) {
            expr = cons(eval(expr.car, env, disableTailCall), expr.cdr);
            goto start;
        } else if (expr.car.type == func_id) {
            LyraFunc func = expr.car.func_val;
            LyraObj args = expr.cdr;
            if (!func.isMacro()){
                args = evalList(args, env);
                if (!disableTailCall && (callStack[callStack.length - 1] is func)) {
                    throw new TailCall(args.cons_val());
                }
                callStack ~= func;
                auto res = func.call(args.cons_val, env);
                callStack = callStack[0 .. $ - 1];
                return res;
            } else {
                callStack ~= func;
                auto res = func.call(args.cons_val(), env);
                callStack = callStack[0 .. $ - 1];
                return eval(res,env);
            }
        } else {
            throw new Exception("Object not callable: " ~ expr.car.toString());
        }
    } else if (expr.type == vector_id) {
        return evalVector(expr, env);
    } else if (expr.type == symbol_id) {
        return env.find(expr);
    } else {
        return expr;
    }
}
