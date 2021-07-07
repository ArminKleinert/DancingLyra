module lyra.types;

import std.conv : to;

alias fixnum = long;
alias floating = double;
alias Func = LyraObj delegate(Env, LyraObj o);
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
    Func func_val;
    Env env_val;
    bool bool_val;
    Vector vector_val;
}

enum : uint {
    nil_id,
    symbol_id,
    string_id,
    char_id,
    fixnum_id,
    real_id,
    cons_id,
    func_id,
    env_id,
    bool_id,
    vector_id
}

class Env {
    const Env parent;
    LyraObj[Symbol] inner;

    alias inner this;

    this(Env parent) {
        this.parent = parent;
    }
}

interface ILyraObj {
    uint type();
    LyraObj objtype();
}

class LyraObj : ILyraObj {
    private static LyraObj ly_true = null;
    private static LyraObj ly_false = null;

    alias value this;

    uint _type = 0;
    Val value = {bool_val: false};

    public override uint type() {
        return _type;
    }

    public override LyraObj objtype() {
        return makeFixnum(_type);
    }

    public static LyraObj makeBoolean(bool e) {
        if (ly_true is null) {
            Val t = {bool_val: true};
            ly_true = new LyraObj(t, bool_id);
            Val f = {bool_val: false};
            ly_false = new LyraObj(f, bool_id);
        }
        return e ? ly_true : ly_false;
    }

    public static LyraObj makeEnv(Env parent, Cons pairs) {
        Env envmap = new Env(parent);
        while (pairs !is Cons.nil()) {
            Symbol key = cast(Symbol)((cast(Cons) pairs.car).car).symbol_val;
            envmap[key] = (cast(Cons) pairs.car).cdr;
            pairs = pairs.next();
        }
        Val v = {env_val: envmap};
        return new LyraObj(v, fixnum_id);
    }

    public static LyraObj makeFixnum(fixnum e) {
        Val v = {fixnum_val: e};
        return new LyraObj(v, fixnum_id);
    }

    public static LyraObj makeSymbol(Symbol e) {
        Val v = {symbol_val: e};
        return new LyraObj(v, symbol_id);
    }

    public static LyraObj makeString(LyraString e) {
        Val v = {string_val: e};
        return new LyraObj(v, string_id);
    }

    public static LyraObj makeChar(char e) {
        Val v = {char_val: e};
        return new LyraObj(v, char_id);
    }

    public static LyraObj makeReal(floating e) {
        Val v = {real_val: e};
        return new LyraObj(v, real_id);
    }

    public static LyraObj makeCons(LyraObj car, LyraObj cdr) {
        return Cons.create(car, cdr);
    }

    public static LyraObj makeFunc(Func e) {
        Val v = {func_val: e};
        return new LyraObj(v, func_id);
    }

    public static LyraObj makeVector(Vector e) {
        Val v = {vector_val: e};
        return new LyraObj(v, vector_id);
    }

    public static LyraObj makeEmpty() {
        return Cons.nil();
    }

    private this(Val value, uint type) {
        this.value = value;
        this._type = type;
    }

    private this() {
    }

    override string toString() {
        switch (type) {
        case symbol_id:
            return this.symbol_val;
        case string_id:
            return "\"" ~ this.string_val ~ "\"";
        case char_id:
            return to!string(this.char_val);
        case fixnum_id:
            return to!string(this.fixnum_val);
        case real_id:
            return to!string(this.real_val);
        case bool_id:
            return this.bool_val ? "#t" : "#f";
        case nil_id:
            return "()";
            //case vector_val:
            //return to!string(this.vector_val());
        default:
            return "<LyraObj type=" ~ to!string(type) ~ ">";
        }
    }
}

class Cons : LyraObj {
    private static Cons theEmptyList = null;

    private LyraObj _car = null;
    private LyraObj _cdr = null;

    public static Cons create(LyraObj _car, LyraObj _cdr) {
        auto c = new Cons(_car, _cdr);
        return c;
    }

    public static Cons nil() {
        if (theEmptyList is null) {
            theEmptyList = new Cons(null, null);
        }
        return theEmptyList;
    }

    public Cons next() {
        if (is(typeof(cdr) == Cons))
            return cast(Cons) getcdr;
        return theEmptyList;
    }

    public LyraObj getcar() {
        return _car;
    }

    public LyraObj getcdr() {
        return _cdr;
    }

    private this(LyraObj _car, LyraObj _cdr) {
        this._car = _car;
        this._cdr = _cdr;
    }

    override uint type() {
        return (this is theEmptyList) ? nil_id : cons_id;
    }

    override LyraObj objtype() {
        return LyraObj.makeFixnum(cons_id);
    }

    override string toString() {
        return listToString(this);
    }
}

Symbol symbol_val(LyraObj obj) {
    return obj.symbol_val;
}

LyraString string_val(LyraObj obj) {
    return obj.string_val;
}

char char_val(LyraObj obj) {
    return obj.char_val;
}

fixnum fixnum_val(LyraObj obj) {
    return obj.fixnum_val;
}

floating real_val(LyraObj obj) {
    return obj.real_val;
}

Cons cons_val(LyraObj obj) {
    import std.stdio;
    return cast(Cons) obj;
}

Func func_val(LyraObj obj) {
    return obj.func_val;
}

bool bool_val(LyraObj obj) {
    return obj.bool_val;
}

Vector vector_val(LyraObj obj) {
    return obj.vector_val;
}

Env env_val(LyraObj obj) {
    return obj.env_val;
}

LyraObj car(LyraObj obj) {
    if (obj.type == cons_id)
        return (cast(Cons) obj).getcar;
    return null;
}

LyraObj cdr(LyraObj obj) {
    if (obj.type == cons_id)
        return (cast(Cons) obj).getcdr;
    return null;
}

LyraObj array_to_list(LyraObj[] arr) {
    if (arr.length == 0)
        return Cons.nil();
    else
        return Cons.create(arr[0], array_to_list(arr[1 .. $]));
}

bool isNil(LyraObj obj) {
    return obj is Cons.nil();
}

string listToString(Cons cons) {
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

    return "(" ~ listToStringHelper(cons) ~ ")";
}
