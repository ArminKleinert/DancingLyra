module lyra.reader;

import std.regex;
import std.stdio;
import std.string;
import std.range.primitives;
import lyra.reader;
import lyra.types;
import std.conv;

const auto RE = ctRegex!(r"[\s,]*([()'`]|" ~ `"` ~ `(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`
        ~ r"`,;)]*)");

class Reader {
    int pos = 0;
    const string[] _tokens;

    this(string[] tokens) {
        _tokens = tokens.dup;
    }

    string peek() {
        if (pos >= _tokens.length)
            return null;
        return _tokens[pos];
    }

    string next() {
        auto token = peek();
        pos++;
        return token;
    }
}

Reader tokenize(string str) {
    string[] tokens;
    foreach (c; matchAll(str, RE)) {
        string token = c[1];
        if (token.length == 0)
            continue;
        if (token[0] == ';')
            continue;
        tokens ~= token;
    }
    return new Reader(tokens);
}

string parse_string(string token) {
    string unescaped = token[1 .. $ - 1] // Remove surrounding quotes
    .replace("\\\\", "\u029e").replace("\\n", "\n").replace("\\\"", "\"").replace("\u029e", "\\");
    return unescaped;
}

auto integer_regex = ctRegex!(r"^-?[0-9]+$");
auto float_regex = ctRegex!(r"^-?[0-9]+\.[0-9]+$");
auto string_regex = ctRegex!(`^"(?:\\.|[^\\"])*"$`);

LyraObj make_ast(Reader tokens, int level = 0) {
    LyraObj[] root = [];
    string token;
    while ((token = tokens.next()) !is null) {
        switch (token) {
        case "(":
            root ~= make_ast(tokens, level + 1);
            break;
        case ")":
            if (level == 0) {
                throw new Exception("Unexpected ')'");
            } else {
                return array_to_list(root);
            }
        case "#t":
            root ~= LyraObj.makeBoolean(true);
            break;
        case "#f":
            root ~= LyraObj.makeBoolean(false);
            break;
        default:
            //auto captures = matchFirst(token, integer_regex);
            if (!matchFirst(token, integer_regex).empty()) {
                root ~= LyraObj.makeFixnum(to!fixnum(token));
            } else if (!matchFirst(token, float_regex).empty()){
                root ~=  LyraObj.makeReal(to!floating(token));
            } else
            if (!matchFirst(token, string_regex).empty()) {
                root ~=  LyraObj.makeString(parse_string(token));
            } else{
            
            root ~= LyraObj.makeSymbol(token);}
            break;
        }
    }
    return array_to_list(root);
}

/*
def make_ast(tokens, level=0)
  root = []
  while (t = tokens.shift) != nil
    case t
    when "("
      root << make_ast(tokens, level+1)
    when ")"
      raise "Unexpected ')'" if level == 0
      return list(*root)
    when '"'                    then raise "Unexpected '\"'"
    when "'()"                  then root << nil
    when "#t"                   then root << true
    when "#f"                   then root << false
    when /^(0b[0-1]+|-?0x[0-9a-fA-F]+|-?[0-9]+)$/
      mult = 1
      if t[0] == "-"
        mult = -1
        t = t[1..-1]
      end
      
      case t[0..1]
      when "0x"
        t = t[2..-1]
        base = 16
      when "0b"
        t = t[2..-1]
        base = 2
      else
        base = 10
      end

      n = t.to_i(base) * mult
      root << n
    when /^-?[0-9]+\.[0-9]+$/
      root << t.to_f
    when /^"(?:\\.|[^\\"])*"$/  then root << parse_str(t)
    else
      if t.start_with?("'")
        root << list(:quote, t[1..-1].to_sym)
      else
        root << t.to_sym
      end
    end
  end
  raise "Expected ')', got EOF" if level != 0
  list(*root)
end
*/
