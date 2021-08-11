module types;

import std.conv : to;
import std.stdio;
import std.string;

alias CallStack = LyraFunc[];

class LyraError : Exception {
    this(string msg, CallStack callStack, string file = __FILE__, size_t line = __LINE__) {
        import std.string;

        super(format("Error! " ~ msg ~ "\nInternal callstack: %s", callStack), file, line);
    }
}

class LyraStackOverflow : Exception {
    this(CallStack callStack, string file = __FILE__, size_t line = __LINE__) {
        import std.string;

        super(format("StackOverflow! Internal callstack: %s", callStack), file, line);
    }
}

class LyraSyntaxError : Exception {
    this(string msg, CallStack callStack, string file = __FILE__, size_t line = __LINE__) {
        import std.string;

        super(format("SyntaxError! " ~ msg ~ "\nInternal callstack: %s", callStack), file, line);
    }
}

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
    LyraObj[] record_val;
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
    box_id = 10,

    unknown_id = uint.max
}

abstract class ALyraFunc : LyraObj, LyraFunc {
    protected const Symbol name;
    private const bool _isMacro;
    protected const uint minargs;
    protected const uint maxargs;
    protected const bool variadic;
    private const bool _ispure;
    private const uint _expectedType;

    nothrow this(Symbol name, uint minargs, uint maxargs, bool variadic,
            bool isMacro, bool ispure, uint _expectedType) {
        this.name = name;
        this.minargs = minargs;
        this.maxargs = maxargs;
        this.variadic = variadic;
        this._isMacro = isMacro;
        this._ispure = ispure;
        this._expectedType = _expectedType;
    }

    nothrow Symbol getName() {
        return name;
    }

    nothrow bool ispure() {
        return ispure;
    }

    nothrow bool isMacro() {
        return _isMacro;
    }

    nothrow uint minArgs() {
        return minargs;
    }

    nothrow uint maxArgs() {
        return maxargs;
    }

    nothrow uint expectedType() {
        return _expectedType;
    }

    abstract LyraObj call(Cons args, Env callEnv);

    nothrow override uint type() {
        return func_id;
    }

    nothrow override string toString() {
        return (_isMacro ? "<macro " : "<function ") ~ name ~ ">";
    }
}

interface LyraFunc {
    nothrow Symbol getName();
    nothrow bool ispure();
    nothrow bool isMacro();
    nothrow uint minArgs();
    nothrow uint maxArgs();
    nothrow uint expectedType();
    LyraObj call(Cons args, Env callEnv);
}

class Env {
    private static Env _globalEnv;

    private Env nextModuleEnv;
    private Env[2] parents;
    private LyraObj[Symbol] inner;
    private Symbol _moduleName;

    alias inner this;

    nothrow this(Symbol moduleName, Env modEnv, Env parent1, Env parent2 = null) {
        nextModuleEnv = modEnv;
        parents[0] = parent1;
        parents[1] = parent2;
        this._moduleName = moduleName;
    }

    nothrow static Env createModuleEnv(Symbol moduleName) {
        Env e = new Env(moduleName, null, globalEnv());
        e.nextModuleEnv = e;
        return e;
    }

    nothrow static Env globalEnv() {
        if (_globalEnv is null) {
            _globalEnv = new Env("global", null, null);
            _globalEnv.nextModuleEnv = _globalEnv;
        }
        return _globalEnv;
    }

    nothrow static void clearGlobalEnv() {
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
        if (v is null && this !is moduleEnv)
            v = moduleEnv.safeFind(sym);
        if (v is null)
            return null;
        return cast(LyraObj) v;
    }

    Env[] getContainingEnvs(LyraObj sym) {
        if (sym.type != symbol_id) {
            throw new Exception("Env.getContainingEnvs expected a symbol, but got " ~ sym.toString());
        }
        return getContainingEnvs(sym.symbol_val, []);
    }

    private Env[] getContainingEnvs(Symbol sym, Env[] envs) {
        auto v = inner.get(sym, null);

        if (v !is null)
            envs ~= this;
        if (parents[0]!is null)
            envs = parents[0].getContainingEnvs(sym, envs);
        if (this !is moduleEnv)
            envs = moduleEnv.getContainingEnvs(sym, envs);
        if (parents[1]!is null)
            envs = parents[1].getContainingEnvs(sym, envs);

        return envs;
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
        if (v is null && this !is moduleEnv)
            v = moduleEnv.safeFind(sym);
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

    string toStringWithoutParents() {
        string s = "";
        foreach (k; inner.byKey())
            s ~= k ~ ": " ~ inner[k].toString() ~ ";\n";
        return s;
    }

    Symbol moduleName() {
        return _moduleName;
    }

    Env moduleEnv() {
        return nextModuleEnv;
    }

    bool isGlobalEnv() {
        return this is _globalEnv;
    }
}

class LyraObj {
    private static LyraObj ly_true = null;
    private static LyraObj ly_false = null;

    private uint _type = 0;
    Val value = {bool_val: false};

    @nogc nothrow public uint type() {
        return _type;
    }

    nothrow public LyraObj objtype() {
        return makeFixnum(type());
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

    nothrow public static LyraObj makeCons(LyraObj car, Cons cdr) {
        return Cons.create(car, cdr);
    }

    nothrow public static LyraObj makeVector(Vector e) {
        Val v = {vector_val: e};
        return new LyraObj(v, vector_id);
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
            return this.value.symbol_val;
        case string_id:
            return "\"" ~ this.value.string_val ~ "\"";
        case char_id:
            return "" ~ this.value.char_val;
        case fixnum_id:
            return to!string(this.value.fixnum_val);
        case real_id:
            return to!string(this.value.real_val);
        case bool_id:
            return this.value.bool_val ? "#t" : "#f";
        case nil_id:
            return "()";
        case vector_id:
            //import std.stdio;

            Vector v = this.value.vector_val;
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
            return "<LyraObj type=" ~ to!string(type) ~ ">";
        }
    }
}

class LyraRecord : LyraObj {
    import lyrafunction;
    import evaluate;

    private static void createAndAddGetter(uint type_id, Symbol typename,
            Symbol memberName, uint memberIdx, Env env) {
        // Create getters
        string getterName = typename ~ "-" ~ memberName;
        auto getter = new NativeLyraFunc(getterName, 1, 1, false, true, false, (xs, env1) {
            if (xs.car.type != type_id) {
                throw new LyraError(getterName ~ ": Invalid input.", callStack());
            }
            return xs.car.value.record_val[memberIdx];
        });
        env.set(getterName, getter);
    }

    private static void createConstructor(uint type_id, Symbol typeName, Symbol[] members, Env env) {
        auto constrName = "make-" ~ typeName;
        auto constructor = new NativeLyraFunc(constrName, members.length % 0xFFFFFFFF,
                members.length % 0xFFFFFFFF, false, true, false, (xs, env1) {
            LyraObj[] inner;
            for (uint i = 0; i < members.length; i++) {
                inner ~= xs.car;
                xs = xs.cdr;
            }
            Val v = {record_val: inner};
            auto obj = new LyraObj(v, type_id);
            return obj;
        });
        env.set(constrName, constructor);
    }

    public static void create(uint type_id, Symbol typeName, Env env, Symbol[] members) {
        // Create getters
        for (uint i = 0; i < members.length; i++) {
            createAndAddGetter(type_id, typeName, members[i], i, env);
        }

        Symbol typeCheckerName = typeName ~ "?";
        auto typeChecker = new NativeLyraFunc(typeCheckerName, 1, 1, false,
                true, false, (xs, env) {
            return LyraObj.makeBoolean(xs.car.type == type_id);
        });
        env.set(typeCheckerName, typeChecker);

        // Create constructor
        createConstructor(type_id, typeName, members, env);
    }
}

class Cons : LyraObj {
    private static Cons theEmptyList = null;

    private LyraObj _car = null;
    private Cons _cdr = null;
    public bool isLiteral = false;

    nothrow public static Cons create(LyraObj _car, Cons _cdr) {
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

    @safe @nogc nothrow public Cons getcdr() {
        return _cdr;
    }

    @safe nothrow private this(LyraObj _car, Cons _cdr) {
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

    @safe nothrow void internalSetCar(LyraObj v) {
        _car = v;
    }

    @safe nothrow void internalSetCdr(Cons v) {
        _cdr = v;
    }
}

@nogc nothrow Symbol symbol_val(LyraObj obj) {
    return obj.value.symbol_val;
}

@nogc nothrow LyraString string_val(LyraObj obj) {
    return obj.value.string_val;
}

@nogc nothrow char char_val(LyraObj obj) {
    return obj.value.char_val;
}

@nogc nothrow fixnum fixnum_val(LyraObj obj) {
    return obj.value.fixnum_val;
}

@nogc nothrow floating real_val(LyraObj obj) {
    return obj.value.real_val;
}

@nogc nothrow Cons cons_val(LyraObj obj) {
    return cast(Cons) obj;
}

@nogc nothrow LyraFunc func_val(LyraObj obj) {
    return cast(LyraFunc) obj;
}

@nogc nothrow bool bool_val(LyraObj obj) {
    return obj.value.bool_val;
}

@nogc nothrow Vector vector_val(LyraObj obj) {
    return obj.value.vector_val;
}

@nogc nothrow LyraObj unbox(LyraObj obj) {
    return obj.value.boxed_val;
}

nothrow Cons cons(LyraObj car, Cons cdr) {
    return Cons.create(car, cdr);
}

@nogc nothrow LyraObj car(LyraObj obj) {
    if (obj.type == cons_id)
        return (cast(Cons) obj).getcar;
    return null;
}

@nogc nothrow Cons cdr(LyraObj obj) {
    if (obj.type == cons_id)
        return (cast(Cons) obj).getcdr;
    return null;
}

nothrow Cons next(LyraObj obj) {
    //if (obj.type == cons_id || obj.type == nil_id)
    //    return cast(Cons) obj.cdr;
    //return Cons.nil();
    return cdr(obj);
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
    return o.type == nil_id || (o.type == bool_id && !o.bool_val);
}

nothrow bool evaluatesToSelf(LyraObj o) {
    return o.type != cons_id;
}
/*
string to_s(fixnum e) {
    return to!string(e);
}

string to_s(floating e) {
    return to!string(e);
}

string ctos(char e) {
    return to!string(e);
}
*/

string typetos(uint e) {
    return to!string(e);
}
