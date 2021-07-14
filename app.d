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

    (define (sum xs acc)
    (if (empty? xs)
      acc
      (begin 5 (sum (cdr xs) (+ acc (car xs))))))

    (define (longrange n)
      (if (= n 0) (list 0) (cons n (longrange (- n 1)))))

    (let* (runs 50)
      (let* (range (longrange 5000))
        (println! (sum range 0))
        (println! (measure runs (lambda () (sum range 0)))))
      ;(println! (measure runs (lambda () (longrange 5000))))
    )"));
    writeln(evalKeepLast(code, Env.globalEnv));
}
