import std.stdio;

import types;
import reader;
import evaluate;
import buildins;
import lyrafunction;

void main() {
    import std.conv : to;

    initializeGlobalEnv(Env.globalEnv);

    auto code = make_ast(tokenize("(define (add n m) (+ n m)) (let ((a 3) (b 6)) (add a b))"));
    //writeln(evalKeepLast(code, Env.globalEnv));

    code = make_ast(tokenize("
    (def-macro (begin x y) (list 'if x y y))
    ;(define (begin x y) (if x y y))

    (define (id e) e)

    (define (sum xs acc)
      (if (empty? xs)
        acc
        (sum (cdr xs) (+ acc (car xs)))))
    
    (define (longrange n)
      (if (= n 0) (list 0) (cons n (longrange (- n 1)))))
      
    (define abc 88)
    (println! abc)
    
    (let* (runs 1)
      (let* (range (longrange 5000))
        (println! (sum range 0))
        (println! (measure runs (lambda () (sum range 0))))
        ))"));
    //writeln(evalKeepLast(code, Env.globalEnv));

    code = make_ast(tokenize("'()"));
    writeln(evalKeepLast(code, Env.globalEnv));
}
