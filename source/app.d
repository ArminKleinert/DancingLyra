import std.stdio;

import lyra.types;
import lyra.reader;
/*
  def list_to_s_helper()
    if cdr.nil?
      car.to_s
    elsif cdr.is_a?(Cons)
      car.to_s + " " + cdr.list_to_s_helper
    else
      car.to_s + " . " + cdr.to_s
    end
  end
  
  def to_s
    "(" + list_to_s_helper() + ")"
  end
  
  def inspect
    to_s
  end
*/
string listToStringHelper(Cons cons) {
  if (cons.isNil) {
    return "";
  }
  if (cons.cdr.isNil) {
    return cons.car.toString();
  }
  if(cons.cdr.type == cons_id) {
    writeln("HERE");
    writeln(cons is null);
    writeln(cons.cdr is null);
    writeln(cons.cdr.cons_val is null);
    return cons.car.toString() ~ " " ~ listToStringHelper(cons.cdr.cons_val);
  }
  return cons.car.toString() ~ " . " ~ cons.cdr.toString();
}
  
string listToString(Cons cons) {
  return "(" ~ listToStringHelper(cons) ~ ")";
}

void main() {
    auto tokens = tokenize("(define (+ n m) (p+ n m))");
    writeln(tokens);
    LyraObj o = make_ast(tokens);
    writeln(o.type);
    writeln(cons_id);
    writeln(listToString(Cons.create(LyraObj.makeFixnum(1),Cons.nil())));
    writeln(listToString(Cons.create(LyraObj.makeFixnum(1),LyraObj.makeFixnum(2))));
    writeln(listToString(Cons.create(LyraObj.makeFixnum(1),Cons.create(LyraObj.makeFixnum(3), Cons.nil()))));
//    writeln(listToString(o.cons_val));
}
