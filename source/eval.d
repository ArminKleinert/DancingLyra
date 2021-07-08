module lyra.eval;

import std.stdio;
import lyra.types;

LyraObj evalList(LyraObj exprList, Env env) {
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

LyraObj evalKeepLast(LyraObj exprList, Env env) {
  if (exprList.isNil())
    return exprList;
  while (!exprList.cdr.isNil) {
    eval(exprList.car, env, true);
    exprList = exprList.next();
  }
  return eval(exprList.car, env);
}

LyraObj eval(LyraObj expr, Env env, bool disableTailCall = false) {
  if (expr.type == cons_id) {

  } else if (expr.type == vector_id) {
    return evalVector(expr, env);
  } else {
    return expr;
  }
}
