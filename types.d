module types;

import std.conv : to;
import std.stdio;
import std.string;

alias fixnum = long;
alias floating = double;
alias Vector = LyraObj[];
alias Symbol = string;
alias LyraString = string;
alias LyraChar = char;

union Val {
    Symbol symbol_val;
    LyraString string_val;
    char char_val;
    fixnum fixnum_val;
    floating real_val;
    bool bool_val;
    Vector vector_val;
    LyraObj boxed_val;
}

enum : uint {
    nil_id = 0,
    symbol_id = 1,
    string_id = 2,
    char_id = 3,
    fixnum_id = 4,
    real_id = 5,
    cons_id = 6,
    func_id = 7,
    bool_id = 8,
    vector_id = 9,
    box_id = 10
}

abstract class LyraFunc : LyraObj {
    protected const Symbol name;
    private const bool _isMacro;
    protected const int minargs;
    protected const int maxargs;
    protected const bool variadic;
    private const bool _ispure;

    nothrow this(Symbol name, int minargs, int maxargs, bool variadic, bool isMacro, bool ispure) {
        this.name = name;
        this.minargs = minargs;
        this.maxargs = maxargs;
        this.variadic = variadic;
        this._isMacro = isMacro;
        this._ispure = ispure;
    }

    nothrow bool ispure() {
        return ispure;
    }

    nothrow bool isMacro() {
        return _isMacro;
    }

    nothrow int minArgs() {
        return minargs;
    }

    nothrow int maxArgs() {
        return maxargs;
    }

    abstract LyraObj call(Cons args, Env callEnv);

    nothrow override uint type() {
        return func_id;
    }

    nothrow override string toString() {
        return "<function " ~ name ~ ">";
    }
}

class Env {
    private static Env _globalEnv;

    private Env[2] parents;
    private LyraObj[Symbol] inner;

    alias inner this;

    nothrow this(Env parent1, Env parent2 = null) {
        parents[0] = parent1;
        parents[1] = parent2;
    }

    static Env globalEnv() {
        if (_globalEnv is null) {
            _globalEnv = new Env(null, null);
        }
        return _globalEnv;
    }

    static void clearGlobalEnv() {
        if (_globalEnv is null) {
            return;
        }
        // Does not really make the map null, but clears it.
        globalEnv().inner = null;
    }

    LyraObj safeFind(Symbol sym) {
        auto v = inner.get(sym, null);
        if (v is null && parents[0]!is null) {
            v = parents[0].safeFind(sym);
        }
        if (v is null && parents[1]!is null) {
            v = parents[1].safeFind(sym);
        }
        if (v is null)
            return null;
        return cast(LyraObj) v;
    }

    Env getContainingEnv(Symbol sym) {
        auto v = inner.get(sym, null);
        if (v !is null)
            return this;
        if (parents[0]!is null) {
            auto temp = parents[0].getContainingEnv(sym);
            if (temp !is null)
                return temp;
        } else if (parents[1]!is null) {
            return parents[1].getContainingEnv(sym);
        }
        return null;
    }

    LyraObj find(LyraObj sym) {
        if (sym.type != symbol_id) {
            throw new Exception("Env.find expected a symbol, but got " ~ sym.toString());
        }
        return find(sym.symbol_val);
    }

    LyraObj find(Symbol sym) {
        auto v = inner.get(sym, null);
        if (v is null && parents[0]!is null) {
            v = parents[0].safeFind(sym);
        }
        if (v is null && parents[1]!is null) {
            v = parents[1].safeFind(sym);
        }
        if (v is null) {
            throw new Exception("No value found for symbol " ~ sym);
        }
        return cast(LyraObj) v;
    }

    void set(LyraObj sym, LyraObj val) {
        if (sym.type != symbol_id) {
            throw new Exception("Env.set expected a symbol, but got " ~ sym.toString());
        }
        set(sym.symbol_val, val);
    }

    nothrow void set(Symbol sym, LyraObj val) {
        this[sym] = val;
    }
}

class LyraObj {
    private static LyraObj ly_true = null;
    private static LyraObj ly_false = null;

    alias value this;

    uint _type = 0;
    Val value = {bool_val: false};

    @nogc nothrow public uint type() {
        if (_type >= 1000)
            return _type - 1000;
        return _type;
    }

    nothrow public LyraObj objtype() {
        if (_type >= 1000)
            return makeFixnum(_type - 1000);
        return makeFixnum(_type);
    }

    @safe nothrow public static LyraObj makeBoolean(bool e) {
        if (ly_true is null) {
            Val t = {bool_val: true};
            ly_true = new LyraObj(t, bool_id);
            Val f = {bool_val: false};
            ly_false = new LyraObj(f, bool_id);
        }
        return e ? ly_true : ly_false;
    }

    @safe nothrow public static LyraObj makeBox(LyraObj e) {
        Val v = {boxed_val: e};
        return new LyraObj(v, box_id);
    }

    nothrow public static LyraObj makeFixnum(fixnum e) {
        Val v = {fixnum_val: e};
        return new LyraObj(v, fixnum_id);
    }

    nothrow public static LyraObj makeSymbol(Symbol e) {
        Val v = {symbol_val: e};
        return new LyraObj(v, symbol_id);
    }

    nothrow public static LyraObj makeString(LyraString e) {
        Val v = {string_val: e};
        return new LyraObj(v, string_id);
    }

    nothrow public static LyraObj makeChar(char e) {
        Val v = {char_val: e};
        return new LyraObj(v, char_id);
    }

    nothrow public static LyraObj makeReal(floating e) {
        Val v = {real_val: e};
        return new LyraObj(v, real_id);
    }

    nothrow public static LyraObj makeCons(LyraObj car, LyraObj cdr) {
        return Cons.create(car, cdr);
    }

    nothrow public static LyraObj makeVector(Vector e) {
        Val v = {vector_val: e};
        return new LyraObj(v, vector_id);
    }

    nothrow public static LyraObj makeWithSpecialType(uint type, LyraObj obj) {
        Val v = {boxed_val: obj};
        if (type < 0)
            type = 0;
        return new LyraObj(v, type + 1000);
    }

    nothrow public static LyraObj makeEmpty() {
        return Cons.nil();
    }

    @safe nothrow private this(Val value, uint type) {
        this.value = value;
        this._type = type;
    }

    @safe nothrow private this() {
    }

    override string toString() {
        switch (type) {
        case symbol_id:
            return this.symbol_val;
        case string_id:
            return "\"" ~ this.string_val ~ "\"";
        case char_id:
            return ctos(this.char_val);
        case fixnum_id:
            return to_s(this.fixnum_val);
        case real_id:
            return to_s(this.real_val);
        case bool_id:
            return this.bool_val ? "#t" : "#f";
        case nil_id:
            return "()";
        case vector_id:
            import std.stdio;

            Vector v = this.vector_val;
            if (v.length == 0)
                return "[]";
            string res = "[";
            for (auto i = 0; i < v.length; i++) {
                res ~= v[i].toString();
                res ~= " ";
            }
            res = res[0 .. $ - 1];
            res ~= "]";
            return res;
        default:
            return "<LyraObj type=" ~ typetos(type) ~ ">";
        }
    }
}

class Cons : LyraObj {
    private static Cons theEmptyList = null;

    private LyraObj _car = null;
    private LyraObj _cdr = null;

    nothrow public static Cons create(LyraObj _car, LyraObj _cdr) {
        auto c = new Cons(_car, _cdr);
        return c;
    }

    nothrow public static Cons nil() {
        if (theEmptyList is null) {
            theEmptyList = Cons.create(null, null);
        }
        return theEmptyList;
    }

    @safe @nogc nothrow public LyraObj getcar() {
        return _car;
    }

    @safe @nogc nothrow public LyraObj getcdr() {
        return _cdr;
    }

    @safe nothrow private this(LyraObj _car, LyraObj _cdr) {
        this._car = _car;
        this._cdr = _cdr;
    }

    @nogc nothrow override uint type() {
        return (this is theEmptyList) ? nil_id : cons_id;
    }

    nothrow override LyraObj objtype() {
        return LyraObj.makeFixnum(type());
    }

    override string toString() {
        string listToStringHelper(Cons cons) {
            if (cons.isNil) {
                return "";
            }
            if (cons.cdr.isNil) {
                return cons.car.toString();
            }
            if (cons.cdr.type == cons_id) {
                return cons.car.toString() ~ " " ~ listToStringHelper(cons.cdr.cons_val);
            }
            return cons.car.toString() ~ " . " ~ cons.cdr.toString();
        }

        return "(" ~ listToStringHelper(this) ~ ")";
    }

    nothrow void internalSetCar(LyraObj v) {
        _car = v;
    }

    nothrow void internalSetCdr(LyraObj v) {
        _cdr = v;
    }
}

nothrow void internalSetCar(LyraObj c, LyraObj val) {
    if (c.type == cons_id)
        c.cons_val.internalSetCar(val);
}

nothrow void internalSetCdr(LyraObj c, LyraObj val) {
    if (c.type == cons_id)
        c.cons_val.internalSetCdr(val);
}

@nogc nothrow Symbol symbol_val(LyraObj obj) {
    return obj.symbol_val;
}

@nogc nothrow LyraString string_val(LyraObj obj) {
    return obj.string_val;
}

@nogc nothrow char char_val(LyraObj obj) {
    return obj.char_val;
}

@nogc nothrow fixnum fixnum_val(LyraObj obj) {
    return obj.fixnum_val;
}

@nogc nothrow floating real_val(LyraObj obj) {
    return obj.real_val;
}

@nogc nothrow Cons cons_val(LyraObj obj) {
    return cast(Cons) obj;
}

@nogc nothrow LyraFunc func_val(LyraObj obj) {
    return cast(LyraFunc) obj;
}

@nogc nothrow bool bool_val(LyraObj obj) {
    return obj.bool_val;
}

@nogc nothrow Vector vector_val(LyraObj obj) {
    return obj.vector_val;
}

@nogc nothrow LyraObj unbox(LyraObj obj) {
    return obj.boxed_val;
}

nothrow Cons cons(LyraObj car, LyraObj cdr) {
    return Cons.create(car, cdr);
}

@nogc nothrow LyraObj car(LyraObj obj) {
    if (obj.type == cons_id)
        return (cast(Cons) obj).getcar;
    return null;
}

@nogc nothrow LyraObj cdr(LyraObj obj) {
    if (obj.type == cons_id)
        return (cast(Cons) obj).getcdr;
    return null;
}

nothrow Cons next(LyraObj obj) {
    if (obj.type == cons_id || obj.type == nil_id)
        return cast(Cons) obj.cdr;
    return Cons.nil();
}

@nogc nothrow bool isNil(LyraObj obj) {
    return obj.type == nil_id;
}

nothrow LyraObj box(LyraObj e) {
    return LyraObj.makeBox(e);
}

@nogc nothrow LyraObj boxSet(LyraObj box, LyraObj e) {
    box.value.boxed_val = e;
    return box;
}

nothrow LyraObj symbol(Symbol e) {
    return LyraObj.makeSymbol(e);
}

nothrow LyraObj obj(fixnum e) {
    return LyraObj.makeFixnum(e);
}

nothrow LyraObj obj(floating e) {
    return LyraObj.makeReal(e);
}

nothrow LyraObj obj(bool e) {
    return LyraObj.makeBoolean(e);
}

nothrow LyraObj obj(LyraString e) {
    return LyraObj.makeString(e);
}

nothrow LyraObj obj(char e) {
    return LyraObj.makeChar(e);
}

nothrow LyraObj newWithType(uint type, LyraObj obj) {
    return LyraObj.makeWithSpecialType(type, obj);
}

nothrow Cons list(Vector e) {
    Cons result = nil();
    while (e.length > 0) {
        result = cons(e[$ - 1], result);
        e = e[0 .. $ - 1];
    }
    return result;
}

nothrow Cons list(LyraObj[] xs...) {
    return list(xs);
}

nothrow LyraObj vector(Vector e) {
    return LyraObj.makeVector(e);
}

nothrow LyraObj vector(LyraObj[] xs...) {
    return LyraObj.makeVector(xs);
}

nothrow Vector listToVector(LyraObj l) {
    Vector v = [];
    while (!l.isNil()) {
        v ~= l.car;
        l = l.next;
    }
    return v;
}

nothrow size_t listSize(Cons xs) {
    size_t res = 0;
    Cons rest = xs;
    while (!isNil(rest)) {
        res++;
        rest = next(rest);
    }
    return res;
}

nothrow bool isConsOrNil(LyraObj o) {
    return (o.type == cons_id) || (o.type == nil_id);
}

nothrow Cons nil() {
    return Cons.nil();
}

nothrow bool isFalsy(LyraObj o) {
    return o.type == cons_id || (o.type == bool_id && !o.bool_val);
}

nothrow bool evaluatesToSelf(LyraObj o) {
    return o.type != cons_id;
}

string to_s(fixnum e) {
    return to!string(e);
}

string to_s(floating e) {
    return to!string(e);
}

string itos(ulong e) {
    return to!string(e);
}

string itos(int e) {
    return to!string(e);
}

string ctos(char e) {
    return to!string(e);
}

string typetos(uint e) {
    return to!string(e);
}
