module lyra.env;

import lyra.types;

LyraObj find(const(Env) env, LyraObj sym) {
    if (sym.type != symbol_id)
        return null;

    auto v = env.inner.get(sym.symbol_val, null);
    if (v is null && env.parent !is null) {
        return find(env.parent, sym);
    }
    return cast(LyraObj) v;
}

void set(Env env, LyraObj sym, LyraObj val) {
    Symbol key = cast(Symbol) sym.symbol_val;
    env[key] = val;
}
