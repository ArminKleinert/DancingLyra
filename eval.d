module evaluate;

import std.stdio;
import types;
import lyrafunction;

alias CallStack = LyraFunc[];
private CallStack callStack = [null];

class LyraStackOverflow : Exception {
    this(CallStack callStack, string file = __FILE__, size_t line = __LINE__) {
        import std.string;

        super(format("StackOverflow! Internal callstack: %s", callStack), file, line);
    }
}

class LyraSyntaxError: Exception {
    this(string msg, CallStack callStack, string file = __FILE__, size_t line = __LINE__) {
        import std.string;

        super(format("SyntaxError! "~msg~ "\nInternal callstack: %s", callStack), file, line);
    }
}

void pushOnCallStack(LyraFunc fn) {
    const auto CALLSTACK_MAX_HEIGHT = 12001;
    if (callStack.length + 1 > CALLSTACK_MAX_HEIGHT) {
        import std.string;

        throw new LyraStackOverflow(callStack);
    }
    callStack ~= fn;
}

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
    if (expr.car.type == symbol_id) {
    auto name = expr.car;
    expr = expr.cdr;
    if (!expr.cdr.isNil()) throw new LyraSyntaxError("define with name can take only 2 arguments (name and single expression).",callStack);
    auto variable = eval(expr.car,env);
    Env.globalEnv.set(name, variable);
    return variable;
    }else if (expr.car.type == cons_id) {auto name = expr.car.car;
    expr = cons(expr.car.cdr, expr.cdr); // Remove name
    auto func = evLambda(expr, env, name.symbol_val, isMacro);
    Env.globalEnv.set(name, func);
    return func;
    }else {throw new LyraSyntaxError ("Illegal expression form for define. First argument must be symbol or cons: " ~ expr.car.toString(),callStack);}
}

LyraObj evLambda(LyraObj expr, Env env, Symbol name = "", bool isMacro = false) {
    if (!isConsOrNil(expr.car))  throw new LyraSyntaxError("Arguments for lambda must be a cons.",callStack);
    auto argNames = expr.car.cons_val;
    auto bodyExpr = expr.next;
    if (bodyExpr.type != cons_id)  throw new LyraSyntaxError("Empty lambda body.",callStack);
    
    auto argVector = listToVector(argNames);
    foreach (a; argVector) {
    if (a.type() != symbol_id) throw new LyraSyntaxError("Argument names for lambda must be symbols.",callStack);}
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
                    if (bindings.car.type() != symbol_id) {throw new  LyraSyntaxError("Invalid form for bindings for let. Name must be symbol.",callStack);}
                    LyraObj sym = bindings.car.car;
                    if (bindings.car.cdr.type() != cons_id) {throw new  LyraSyntaxError("Invalid form for bindings for let.",callStack);}
                    LyraObj val = bindings.car.cdr.car;
                    env.set(sym, val);
                    bindings = bindings.cdr;
                }
                return evalKeepLast(expr.cdr, env, disableTailCall);
            case "let*":
                expr = expr.cdr;
                LyraObj binding = expr.car;
                env = new Env(env);
                if (binding.car.type() != symbol_id) {throw new LyraSyntaxError("Invalid form for bindings for let. Name must be symbol.",callStack);}
                LyraObj sym = binding.car;
                if (binding.cdr.type() != cons_id) {throw new LyraSyntaxError("Invalid form for bindings for let.",callStack);}
                LyraObj val = eval(binding.cdr.car, env, true);
                env.set(sym, val);
                auto res = evalKeepLast(expr.cdr, env, disableTailCall);
                return res;
            case "lambda":
                return evLambda(expr.cdr, env);
            case "if":
                  if (expr.cdr.type() != cons_id) throw new LyraSyntaxError("Empty if.",callStack);
                expr = expr.cdr;
                LyraObj condition = eval(expr.car, env, true);
                expr = expr.cdr;
                  if (expr.type() != cons_id) throw new LyraSyntaxError("Empty cases for if.",callStack);if (condition.isNil || (condition.type == bool_id && condition.bool_val == true)) {
                    return eval(expr.car, env, disableTailCall);
                } else {
                if (expr.cdr.isNil()) return nil(); // If else-branch is empty, return nil
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
            if (!func.isMacro()) {
                if (!disableTailCall && (callStack[callStack.length - 1] is func)) {
                    args = evalList(args, env);
                    throw new TailCall(args.cons_val());
                }
                pushOnCallStack(func);
                args = evalList(args, env);
                auto res = func.call(args.cons_val, env);
                callStack = callStack[0 .. $ - 1];
                return res;
            } else {
                pushOnCallStack(func);
                auto res = func.call(args.cons_val(), env);
                callStack = callStack[0 .. $ - 1];
                return eval(res, env);
            }
        } else {
            throw new LyraSyntaxError("Object not callable: " ~ expr.car.toString(),callStack);
        }
    } else if (expr.type == vector_id) {
        return evalVector(expr, env);
    } else if (expr.type == symbol_id) {
        return env.find(expr);
    } else {
        return expr;
    }
}
