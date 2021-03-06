module evaluate;

import std.stdio;
import types;
import lyrafunction;

private CallStack _callStack = [null];
private Symbol[] importedModules = [];

private bool allowRedefine = false;
private bool globalDisallowTailRecursion = false;
private bool optimize = false;

CallStack callStack() {
    return _callStack;
}

void eval_AllowRedefine() {
    allowRedefine = true;
}

void eval_DisallowTailRecursion() {
    globalDisallowTailRecursion = true;
}

void eval_DoOptimize() {
    optimize = true;
}

void checkForRedefinition(Symbol sym, Env env) {
    if (allowRedefine) {
        return;
    }
    if (env.moduleEnv.safeFind(sym) !is null) {
        throw new LyraSyntaxError("Redefinition of symbol is not allowed! " ~ sym, callStack);
    }
}

bool checkFulfillsPredsForValueInline(LyraObj sym, Env env) {
    if (!allowRedefine && (sym.type == symbol_id)) {
        //&& (Env.globalEnv.safeFind(sym.symbol_val) !is null)
        auto containingEnvs = env.getContainingEnvs(sym);
        if (containingEnvs.length == 0)
            return false;

        foreach (found; containingEnvs) {
            //writeln(found.toStringWithoutParents);
            if (found != Env.globalEnv)
                return false;
        }

        return true;
    } else {
        return false;
    }
}

void inlineValueIntoCarIfPossible(LyraObj checkValue, LyraObj exprList, LyraObj val, Env env) {
    if (checkFulfillsPredsForValueInline(checkValue, env)) {
        (cast(Cons) exprList).internalSetCar(val);
    }
}

void pushOnCallStack(LyraFunc fn) {
    const auto CALLSTACK_MAX_HEIGHT = 12001;
    if (_callStack.length + 1 > CALLSTACK_MAX_HEIGHT) {
        import std.string;

        throw new LyraStackOverflow(_callStack);
    }
    _callStack ~= fn;
}

LyraObj macroExpand(LyraFunc f, Cons args, Env env) {
    pushOnCallStack(f);
    auto res = f.call(args, env);
    _callStack = _callStack[0 .. $ - 1];
    return res;
}

Cons evalList(LyraObj exprList, Env env, bool allowInlineIfEnabled = true) {
    Vector v = [];
    while (!exprList.isNil) {
        auto temp = eval(exprList.car, env, true);
        v ~= temp;
        inlineValueIntoCarIfPossible(exprList.car, exprList, temp, env);
        exprList = exprList.next();
    }
    return list(v);
}

LyraObj evalVector(LyraObj expr, Env env) {
    Vector v = vector_val(expr);
    Vector vnew = [];
    for (auto i = 0; i < v.length; i++)
        vnew ~= eval(v[i], env, true);
    return vector(vnew);
}

LyraObj evModule(Cons expr) {
    LyraObj moduleName = expr.cdr.car;
    if (moduleName.type != symbol_id)
        throw new LyraSyntaxError("Module name must be a symbol.", _callStack);

    Symbol moduleNameSymbol = moduleName.symbol_val;
    foreach (m; importedModules) {
        if (m == moduleNameSymbol)
            return moduleName;
    }
    importedModules ~= moduleNameSymbol;

    Env moduleEnv = Env.createModuleEnv(moduleNameSymbol);
    LyraObj exportBindings = expr.cdr.cdr.car;
    if (exportBindings.type != vector_id)
        throw new LyraSyntaxError("Module export bindings must be a vector.", _callStack);
    Cons forms = expr.cdr.cdr.next();

    evalKeepLast(forms, moduleEnv);

    Vector bindings = exportBindings.vector_val;
    foreach (binding; bindings) {
        if (binding.type != vector_id || binding.vector_val.length != 2) {
            throw new LyraSyntaxError("Module binding must be a vector of 2 elements.", _callStack);
        }

        Vector bindingv = binding.vector_val;

        if (bindingv[0].type != symbol_id) {
            throw new LyraSyntaxError("Module binding export name must be a symbol.", _callStack);
        }

        checkForRedefinition(bindingv[0].symbol_val, Env.globalEnv());
        Env.globalEnv().set(bindingv[0].symbol_val, eval(bindingv[1], moduleEnv));
    }

    return moduleName;
}

LyraObj evalKeepLast(LyraObj exprList, Env env, bool disableTailCall = false) {
    if (exprList.isNil()) {
        return exprList;
    }

    if (optimize) {
        auto exprList1 = exprList;
        while (!exprList1.cdr.isNil && !exprList1.cdr.cdr.isNil) {
            // If optimizations are on and the expression is trivial, evaluate it once
            // to make sure that evaluation is possible. Then delete it from the AST.
            if (evaluatesToSelf(exprList1.car)) {
                eval(exprList1.car, env, disableTailCall);
                (cast(Cons) exprList).internalSetCar(exprList1.cdr.car);
                (cast(Cons) exprList).internalSetCdr(exprList1.cdr.cdr);
            } else {
                exprList1 = exprList1.cdr;
            }
        }
    }

    while (!(exprList.cdr.isNil)) {
        auto temp = exprList.car;
        eval(temp, env, true);
        exprList = exprList.cdr;
    }

    auto temp = eval(exprList.car, env, disableTailCall);
    inlineValueIntoCarIfPossible(exprList.car, exprList, temp, env);

    return temp;
}

LyraObj evDefine(LyraObj expr, Env env, bool isMacro) {
    if (expr.car.type == symbol_id) {
        auto name = expr.car;
        expr = expr.cdr;
        if (!expr.cdr.isNil())
            throw new LyraSyntaxError("define with name can take only 2 arguments (name and single expression).",
                    _callStack);
        auto variable = eval(expr.car, env);
        checkForRedefinition(name.symbol_val, env);
        env.moduleEnv.set(name, variable);
        return variable;
    } else if (expr.car.type == cons_id) {
        auto name = expr.car.car;

        if (name.type != symbol_id) {
            throw new LyraSyntaxError("Name in function definition must be a symbol. " ~ name.toString(),
                    _callStack);
        }

        checkForRedefinition(name.symbol_val, env);

        expr = Cons.create(expr.car.cdr, expr.cdr); // Remove name
        auto func = evLambda(expr, env, name.symbol_val, isMacro);
        env.moduleEnv.set(name, func);
        return func;
    } else {
        throw new LyraSyntaxError(
                "Illegal expression form for define. First argument must be symbol or cons: " ~ expr.car.toString(),
                callStack);
    }
}

LyraObj evLambda(LyraObj expr, Env env, Symbol name = "", bool isMacro = false) {
    if (!isConsOrNil(expr.car))
        throw new LyraSyntaxError("Arguments for lambda must be a cons.", callStack);
    auto argNames = expr.car.cons_val;

    auto bodyExpr = expr.next;
    if (bodyExpr.type != cons_id)
        throw new LyraSyntaxError("Empty lambda body.", callStack);

    auto argVector = listToVector(argNames);
    foreach (a; argVector) {
        if (a.type() != symbol_id)
            throw new LyraSyntaxError("Argument names for lambda must be symbols.", callStack);
    }
    auto variadic = argVector.length > 1 && argVector[argVector.length - 2].symbol_val == "&";
    int arity = cast(int) argVector.length;

    if (variadic) {
        arity -= 2;
        Cons temp = nil();
        for (auto i = argVector.length - 1; i > 0; i--) {
            if (i != argVector.length - 2) {
                temp = Cons.create(argVector[i], temp);
            }
            argNames = temp;
        }
        if (argVector.length > 2)
            argNames = Cons.create(argVector[0], argNames);
    }

    auto ispure = false; // TODO

    return new NonNativeLyraFunc(name, env, arity, argNames, bodyExpr, variadic, ispure, isMacro);
}

LyraObj eval(LyraObj expr, Env env, bool disableTailCall = false) {
    if (expr.type == cons_id) {
        if (expr.car.type == symbol_id) {
            switch (expr.car.symbol_val) {
            case "module":
                return evModule(expr.cons_val);
            case "quote":
                if (expr.cdr.isNil())
                    return Cons.nil();
                return expr.cdr.car;
            case "define":
                return evDefine(expr.cdr, env, false);
            case "def-macro":
                return evDefine(expr.cdr, env, true);
            case "let":
                expr = expr.cdr;
                LyraObj bindings = expr.car;
                env = new Env("", env.moduleEnv, env);
                while (!bindings.isNil) {
                    LyraObj sym = bindings.car.car;
                    if (sym.type() != symbol_id) {
                        throw new LyraSyntaxError("Invalid form for bindings for let. Name must be symbol.",
                                callStack);
                    }

                    if (bindings.car.cdr.type() != cons_id) {
                        throw new LyraSyntaxError("Invalid form for bindings for let.", callStack);
                    }

                    LyraObj valExpr = bindings.car.cdr.car;
                    LyraObj val = eval(valExpr, env);

                    inlineValueIntoCarIfPossible(valExpr, bindings.car.cdr, val, env);

                    env.set(sym, val);
                    bindings = bindings.cdr;
                }
                return evalKeepLast(expr.cdr, env, disableTailCall);
            case "let*":
                expr = expr.cdr;
                LyraObj binding = expr.car;
                env = new Env("", env.moduleEnv, env);
                if (binding.car.type() != symbol_id) {
                    throw new LyraSyntaxError("Invalid form for bindings for let. Name must be symbol.",
                            callStack);
                }

                LyraObj sym = binding.car;
                if (binding.cdr.type() != cons_id) {
                    throw new LyraSyntaxError("Invalid form for bindings for let.", callStack);
                }

                LyraObj valExpr = binding.cdr.car;
                LyraObj val = eval(valExpr, env, true);
                inlineValueIntoCarIfPossible(valExpr, binding.cdr, val, env);

                env.set(sym, val);
                auto res = evalKeepLast(expr.cdr, env, disableTailCall);
                return res;
            case "lambda":
                auto f = evLambda(expr.cdr, env, "", false);
                // TODO: This optimization is supposed to make it so the function is only created once but it does not work at all...
                //if (optimize) {
                //    expr.internalSetCar(symbol("quote"));
                //    expr.internalSetCdr(list(f));
                //}
                return f;
            case "if":
                if (expr.cdr.type() != cons_id) {
                    throw new LyraSyntaxError("Empty if.", callStack);
                }

                expr = expr.cdr;
                LyraObj condition = expr.car;
                expr = expr.cdr;

                if (expr.type() != cons_id) {
                    throw new LyraSyntaxError("Empty cases for if.", callStack);
                }

                auto evaluatedCondition = eval(condition, env, true);
                if (!evaluatedCondition.isFalsy()) {
                    return eval(expr.car, env, disableTailCall);
                } else {
                    if (expr.cdr.isNil())
                        return nil(); // If else-branch is empty, return nil
                    return eval(expr.cdr.car, env, disableTailCall);
                }
            case "cond":
                auto cases = expr.cdr;
                if (cases.car.type != cons_id) {
                    throw new LyraSyntaxError("cond: List expected.", callStack);
                }
                LyraObj res = nil();

                while (!cases.isNil()) {
                    if (cases.car.type != cons_id)
                        throw new LyraSyntaxError("cond: List expected.", callStack);

                    auto case0 = cases.car;
                    auto condition = case0.car;

                    if (case0.cdr.isNil()) {
                        throw new LyraSyntaxError("cond: Invalid branch for condition " ~ condition.toString(),
                                callStack);
                    }

                    auto evaluatedCondition = eval(condition, env, true);
                    inlineValueIntoCarIfPossible(condition, case0, evaluatedCondition, env);

                    if (!evaluatedCondition.isFalsy()) {
                        auto temp = eval(case0.cdr.car, env);
                        inlineValueIntoCarIfPossible(case0.cdr.car, case0.cdr, temp, env);
                        return temp;
                    }

                    cases = cases.cdr;
                }
                // No true case found, default to nil
                return nil();
            case "apply":
                auto fn = car(cdr(expr));
                auto args = cdr(expr).next();
                Vector args1 = [];
                while (!cdr(args).isNil()) {
                    args1 ~= args.car;
                    args = args.next();
                }
                auto lastArg = eval(list(symbol("->list"), args.car), env);
                args1 ~= listToVector(lastArg);
                expr = Cons.create(fn, list(args1));
                return eval(expr, env);
            case "macro-expand":
                LyraFunc func = eval(expr.cdr.car.car, env).func_val;
                Cons args = expr.cdr.car.next;
                auto res = macroExpand(func, args, env);
                return res;
            default:
                auto found = env.safeFind(expr.car.value.symbol_val);
                if (found is null) {
                    throw new LyraSyntaxError("Unresolved symbol: " ~ expr.car.toString(),
                            callStack);
                }
                expr = Cons.create(found, expr.cdr);
                return eval(expr, env, disableTailCall);
            }
        } else if (expr.car.type == cons_id) {
            expr = Cons.create(eval(expr.car, env, disableTailCall), expr.cdr);
            return eval(expr, env, disableTailCall);
        } else if (expr.car.type == func_id) {
            LyraFunc func = expr.car.func_val;
            LyraObj args = expr.cdr;
            if (!func.isMacro()) {
                if (!globalDisallowTailRecursion && !disableTailCall
                        && (callStack[callStack.length - 1] is func)) {
                    args = evalList(args, env);
                    throw new TailCall(args.cons_val());
                }
                pushOnCallStack(func);
                args = evalList(args, env);
                auto res = func.call(args.cons_val, env);
                _callStack = _callStack[0 .. $ - 1];
                return res;
            } else {
                auto res = macroExpand(func, args.cons_val, env);
                return eval(res, env);
            }
        } else {
            throw new LyraSyntaxError("Object not callable: " ~ expr.car.toString(), callStack);
        }
    }
    if (expr.type == vector_id) {
        return evalVector(expr, env);
    } else if (expr.type == symbol_id) {
        auto found = env.safeFind(expr.value.symbol_val);
        if (found is null) {
            throw new LyraSyntaxError("Unresolved symbol: " ~ expr.toString(), callStack);
        }
        return found;
    } else {
        return expr;
    }
}
