module lyra.reader;

import std.regex;
import std.stdio;
import std.string;
import std.range.primitives;
import lyra.reader;
import lyra.types;
import std.conv;

const auto RE = ctRegex!(
        r"[\s,]*([\[\]()'`]|" ~ `"` ~ `(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"` ~ r"`,;)]*)");

class Reader {
    private int pos = 0;
    private const string[] _tokens;

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

LyraObj make_ast(Reader tokens, int level = 0, string expected = "", bool stop_after_1 = false) {
    LyraObj[] root = [];
    string token;
    while ((token = tokens.next()) !is null) {
        switch (token) {
        case "'":
            root ~= list([symbol("quote"), make_ast(tokens, level, "", true)]);
            break;
        case "(":
            root ~= make_ast(tokens, level + 1, ")");
            break;
        case "[":
            root ~= make_ast(tokens, level + 1, "]");
            break;
        case ")":
            if (level == 0 || expected != ")") {
                throw new Exception("Unexpected ')'");
            }
            return list(root);
        case "]":
            if (level == 0 || expected != "]") {
                throw new Exception("Unexpected ']'");
            }
            return vector(root);
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
            } else if (!matchFirst(token, float_regex).empty()) {
                root ~= LyraObj.makeReal(to!floating(token));
            } else if (!matchFirst(token, string_regex).empty()) {
                root ~= LyraObj.makeString(parse_string(token));
            } else {

                root ~= LyraObj.makeSymbol(token);
            }
            break;
        }
        if (stop_after_1) {
            return root[0];
        }
    }
    return list(root);
}
