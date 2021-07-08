module lyra.eval;

import std.stdio;
import lyra.types;

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

LyraObj evalKeepLast(LyraObj exprList, Env env,bool disableTailCall = false) {
  if (exprList.isNil())
    return exprList;
  while (!exprList.cdr.isNil) {
    eval(exprList.car, env, true);
    exprList = exprList.next();
  }
  return eval(exprList.car, env, disableTailCall);
}

LyraObj evDefine(LyraObj expr, Env env, bool ismacro) {
// TODO
return null;
}

LyraObj evLambda(LyraObj expr, Env env) {
// TODO
return null;
}

LyraObj eval(LyraObj expr, Env env, bool disableTailCall = false) {
  do {
  if (expr.type == cons_id) {
    if (expr.car.type == symbol_id) {
      switch (expr.car.symbol_val) {
      case "quote":
        return expr.cdr;
      case "define":
        return evDefine(expr, env, false);
      case "def-macro":
        return evDefine(expr, env, false);
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
        return evalKeepLast(expr.cdr, env, disableTailCall);
      case "lambda":
        return evLambda(expr, env);
      case "if":
        // TODO Arity check here
        expr = expr.cdr;
        LyraObj condition = eval(expr.car, env, true);
        expr = expr.cdr;
        if (condition.isNil
          || (condition.type == bool_id && condition.bool_val == false)) {
          return eval(expr.car, env, disableTailCall);
        } else  {
         return eval(expr.cdr.car, env, disableTailCall);
        }
      case "cond":
        // TODO
        return nil();
      case "apply":
        // TODO
        return nil();
      default:
        
      }
    } else if (expr.car.type == cons_id) {
      expr = cons(eval(expr.car, env, disableTailCall), expr.cdr);
      continue; // Start again.
    } else if (expr.car.type == func_id) {
      LyraObj args = evalList(expr.cdr, env);
      // TODO
    }
  } else if (expr.type == vector_id) {
    return evalVector(expr, env);
  } else {
    return expr;
  }
  } while (false);
  return nil();
}
