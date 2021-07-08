module lyra.types;

import std.conv : to;
import std.stdio;

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
  vector_id,
  box_id
}

class LyraFunc : LyraObj {
  private string name; private Env definitionEnv; private Cons argNames; private LyraObj bodyExpr;

  this(string name, Env definitionEnv, Cons argNames, LyraObj bodyExpr) {
  this.name = name;
  this.definitionEnv = definitionEnv;
  this.argNames = argNames;
  this.bodyExpr = bodyExpr;
  }
  
  LyraObj call(Cons args, Env callEnv) {
  import lyra.eval;
  
    Env env = new Env(definitionEnv, callEnv);
    LyraObj result;
    
    do {
      Cons argNames1 = argNames;
      while (!argNames1.isNil){
      if (args.isNil) throw new Exception("Not enough arguments for function "~name~"!");
      
      env.set(argNames1.car, args.car);
      argNames1 = argNames1.next;
      args = args.next;
      }
      
      try {
        result =eval(bodyExpr, env);
      } catch(TailCall tc) {
      args = tc.args;
          continue ;
      } catch (Exception ex) {
      writeln(name ~" failed with error " ~ ex.msg);
      writeln("Arguments: " ~ args.toString());
      throw ex;
      }
    }while(false);
    
    return result;
  }

  override uint type() {
    return func_id;
  }
  
  override string toString() {
  return "<function " ~ name ~ ">";
  }
}

class TailCall : Exception {
  Cons args;
      this(Cons args,string msg="", string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);this.args = args;
    }
}

class Env  {
  private Env[2] parents;
  private LyraObj[Symbol] inner;

  alias inner this;

  this(Env parent1, Env parent2 = null) {
    parents[0]=parent1;
    parents[1]=parent2;
  }

   LyraObj find(LyraObj sym) {
    if (sym.type != symbol_id)
      return null;

    auto v = inner.get(sym.symbol_val, null);
    if (v is null && parents[0] !is null) {
      return parents[0].find(sym);
    }
    if (v is null && parents[1] !is null) {
      return parents[1].find(sym);
    }
    return cast(LyraObj) v;
  }

   void set(LyraObj sym, LyraObj val) {
    Symbol key = sym.symbol_val;
    writeln("Key: " ~ key ~ " Value: " ~ val.toString());
    this[key] = val;
  }
}

class LyraObj {
  private static LyraObj ly_true = null;
  private static LyraObj ly_false = null;

  alias value this;

  uint _type = 0;
  Val value = {bool_val: false};

  public uint type() {
    return _type;
  }

  public LyraObj objtype() {
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

  public static LyraObj makeBox(LyraObj e) {
    Val v = {boxed_val: e};
    return new LyraObj(v, box_id);
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
  return cast(Cons) obj;
}

LyraFunc func_val(LyraObj obj) {
  return cast(LyraFunc) obj;
}

bool bool_val(LyraObj obj) {
  return obj.bool_val;
}

Vector vector_val(LyraObj obj) {
  return obj.vector_val;
}

LyraObj unbox(LyraObj obj) {
  return obj.boxed_val;
}

Cons cons(LyraObj car, LyraObj cdr) {
  return Cons.create(car, cdr);
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

Cons next(LyraObj obj) {
  if (obj.type == cons_id)
    return cast(Cons) obj.cdr;
  return Cons.nil();
}

bool isNil(LyraObj obj) {
  return obj is Cons.nil();
}

LyraObj box(LyraObj e) {
  return LyraObj.makeBox(e);
}

LyraObj boxSet(LyraObj box, LyraObj e) {
  box.value.boxed_val = e;
  return box;
}

LyraObj symbol(Symbol e) {
  return LyraObj.makeSymbol(e);
}

LyraObj obj(fixnum e) {
  return LyraObj.makeFixnum(e);
}

LyraObj obj(floating e) {
  return LyraObj.makeReal(e);
}

LyraObj obj(bool e) {
  return LyraObj.makeBoolean(e);
}

LyraObj obj(LyraString e) {
  return LyraObj.makeString(e);
}

LyraObj obj(char e) {
  return LyraObj.makeChar(e);
}

Cons list(Vector e) {
  Cons result = nil();
  while (e.length > 0) {
    result = cons(e[$ - 1], result);
    e = e[0 .. $ - 1];
  }
  return result;
}

Cons list(LyraObj[] xs...) {
  return list(xs);
}

LyraObj vector(Vector e) {
  return LyraObj.makeVector(e);
}

LyraObj vector(LyraObj[] xs...) {
  return LyraObj.makeVector(xs);
}

Cons nil() {
  return Cons.nil();
}
