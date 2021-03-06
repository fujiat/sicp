(load "./table")
(use slib)
(require 'trace)

(define (attach-tag type-tag contents)
  (if (eq? type-tag 'scheme-number)
      contents
      (cons type-tag contents)))

(define (type-tag datum)
  (cond ((pair? datum)
         (car datum))
        ((number? datum)
         'scheme-number)
        (else
         (error "bad tagged datum -- type-tag" datum))))

(define (contents datum)
  (cond ((pair? datum)
         (cdr datum))
        ((number? datum)
         datum)
        (else
         (error "bad tagged datum -- contents" datum))))

(define (type-higher? type1 type2)
  (let ((type-tower '(complex real scheme-number)))
    (define (iter twr)
      (if (null? twr)
          #f
          (cond ((eq? type1 (car twr)) type1)
                ((eq? type2 (car twr)) type2)
                (else (iter (cdr twr))))))
    (iter type-tower)))

(define (drop x)
  (if (pair? x)
      (let ((projected (project x)))
        (if projected
            (if (and (not (eq? (type-tag x) 'rational)) (equ? (raise projected) x))
                (drop projected)
                x)
            x))
      x))

(define (coerce-to x tag)
  (if (eq? (type-tag x) tag)
      x
      (coerce-to (raise x) tag)))

(define (coerce-higher-type args)
  (let ((a1 (car args))
        (a2 (cadr args)))
    (let ((type1 (type-tag a1))
          (type2 (type-tag a2)))
      (if (eq? type1 type2)
          args
          (let ((tag (type-higher? type1 type2)))
            (if (eq? tag type1)
                (coerce-higher-type (list a1 (raise a2)))
                (coerce-higher-type (list (raise a1) a2))))))))
        

(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
          (drop (apply proc (map contents args)))
          (if (= (length args) 2)
              (let ((type1 (car type-tags))
                    (type2 (cadr type-tags)))
                (if (not (eq? type1 type2))
                    (let ((coerced-args (coerce-higher-type args)))
                      (let ((proc2 (get op (map type-tag coerced-args))))
                        (if proc2
                            (drop (apply proc2 (map contents coerced-args)))
                            (error "no method for these types" (list op type-tags)))))
                    (error "no method for these types"
                           (list op type-tags))))
              (error "no method for these types"
                     (list op type-tags)))))))

;; 汎用選択子
(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))
(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))
;; 2.79追加
(define (equ? x y) (apply-generic 'equ? x y))
;; 2.80追加
(define (=zero? x) (apply-generic '=zero? x))
;; 2.88追加
(define (negative x) (apply-generic 'negative x))
;; 2.83追加
(define (raise x)
  (let ((proc (get 'raise (type-tag x))))
    (if proc
        (proc (contents x))
        #f)))

(define (project x)
  (let ((proc (get 'project (type-tag x))))
    (if proc
        (proc (contents x))
        #f)))

(define (greatest-common-divisor x y)
  (apply-generic 'greatest-common-divisor x y))

;; 直交座標表現
(define (install-rectangular-package)
   ;; 内部手続き
  (define (real-part z) (car z))
  (define (imag-part z) (cdr z))
  (define (make-from-real-imag x y) (cons x y))
  (define (magnitude z)
    (sqrt (+ (square (real-part z))
             (square (imag-part z)))))
  (define (angle z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a) 
    (cons (* r (cos a)) (* r (sin a))))

   ;; システムの他の部分とのインターフェース
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular 
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular 
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

;; 極座標表現
(define (install-polar-package)
   ;; 内部手続き
  (define (magnitude z) (car z))
  (define (angle z) (cdr z))
  (define (make-from-mag-ang r a) (cons r a))
  (define (real-part z)
    (* (magnitude z) (cos (angle z))))
  (define (imag-part z)
    (* (magnitude z) (sin (angle z))))
  (define (make-from-real-imag x y) 
    (cons (sqrt (+ (square x) (square y)))
          (atan y x)))

   ;; システムの他の部分とのインターフェース
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar 
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)


(define (install-scheme-number-package)

  (define (gcd a b)
    (if (= b 0)
        a
        (gcd b (remainder a b))))
  
  (define (tag x)
    (attach-tag 'scheme-number x))    
  (put 'add '(scheme-number scheme-number)
       (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number)
       (lambda (x y) (tag (- x y))))
  (put 'mul '(scheme-number scheme-number)
       (lambda (x y) (tag (* x y))))
  (put 'div '(scheme-number scheme-number)
       (lambda (x y) (tag (/ x y))))
  (put 'make 'scheme-number
       (lambda (x) (tag x)))
  
  ;; 2.79追加
  (put 'equ? '(scheme-number scheme-number) =)

  ;; 2.80追加
  (put '=zero? '(scheme-number)
       (lambda (x) (= x 0)))
  ;; 2.83追加
  (put 'raise 'scheme-number
       (lambda (x) (make-rational x 1)))
  ;; 2.88追加
  (put 'negative '(scheme-number)
       (lambda (x) (tag (- x))))

  (put 'greatest-common-divisor '(scheme-number scheme-number)
       (lambda (x y) (gcd x y)))
  
  'done)

(define (make-scheme-number n)
  ((get 'make 'scheme-number) n))


(define (install-rational-package)
   ;; 内部手続き
  (define (numer x) (car x))
  (define (denom x) (cdr x))
  (define (make-rat n d)
    (cons n d))
  (define (add-rat x y)
    (make-rat (add (mul (numer x) (denom y))
                   (mul (numer y) (denom x)))
              (mul (denom x) (denom y))))
  (define (sub-rat x y)
    (make-rat (sub (mul (numer x) (denom y))
                   (mul (numer y) (denom x)))
              (mul (denom x) (denom y))))
  (define (mul-rat x y)
    (make-rat (mul (numer x) (numer y))
              (mul (denom x) (denom y))))
  (define (div-rat x y)
    (make-rat (mul (numer x) (denom y))
              (mul (denom x) (numer y))))

  ;; 2.79追加
  (define (equ-rat? x y)
    (and (= (numer x) (numer y))
         (= (denom x) (denom y))))

  ;; 2.80追加
  (define (=zero-rat? x)
    (= (numer x) 0))
  
  ;; 2.83追加
  (define (raise-rat x)
    (make-real (div (numer x) (denom x))))
  
  (define (rational->integer x)
    (make-scheme-number (div (numer x) (denom x))))
    
  ;; システムの他の部分へのインターフェース
  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational)
       (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational)
       (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational)
       (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational)
       (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational
       (lambda (n d) (tag (make-rat n d))))

  ;; 2.79追加
  (put 'equ? '(rational rational) equ-rat?)

  ;; 2.80追加
  (put '=zero? '(rational) =zero-rat?)

  ;; 2.83追加
  (put 'raise 'rational raise-rat)

  (put 'project 'rational rational->integer)

  ;; 2.88追加
  (put 'negative '(rational)
       (lambda (x) (make-rat (- (numer x)) (denom x))))
  'done)
  
(define (make-rational n d)
  ((get 'make 'rational) n d))

(define (install-real-package)
  (define (real->integer x)
    (round x))
  (define (real->rational x)
    (make-rational (* x 100000) 100000))
  (define (tag x) (attach-tag 'real x))
  (put 'add '(real real)
       (lambda (x y) (tag (+ x y))))
  (put 'sub '(real real)
       (lambda (x y) (tag (- x y))))
  (put 'mul '(real real)
       (lambda (x y) (tag (* x y))))
  (put 'div '(real real)
       (lambda (x y) (tag (/ x y))))
  (put 'equ? '(real real)
       (lambda (x y) (= x y)))
  (put '=zero? '(real)
       (lambda (x) (= x 0.0)))
  (put 'make 'real
       (lambda (x) (tag (* x 1.0))))
  (put 'raise 'real
       (lambda (x) (make-complex-from-real-imag x 0)))
  (put 'project 'real real->rational)
  
  ;;2.88追加
  (put 'negative '(real)
       (lambda (x) (tag (- x))))
  'done)

(define (make-real n)
  ((get 'make 'real) n))

(define (install-complex-package)

  ;; 直交座標と極座標パッケージから取り入れた手続き
  (define (make-from-real-imag x y)
    ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a)
    ((get 'make-from-mag-ang 'polar) r a))

   ;; 内部手続き
  (define (add-complex z1 z2)
    (make-from-real-imag (+ (real-part z1) (real-part z2))
                         (+ (imag-part z1) (imag-part z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (- (real-part z1) (real-part z2))
                         (- (imag-part z1) (imag-part z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (* (magnitude z1) (magnitude z2))
                       (+ (angle z1) (angle z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (/ (magnitude z1) (magnitude z2))
                       (- (angle z1) (angle z2))))

  ;; 2.79追加
  (define (equ-complex? z1 z2)
    (and (= (real-part z1) (real-part z2))
         (= (imag-part z1) (imag-part z2))))

  ;; 2.80追加
  (define (=zero-complex? z)
    (and (= (real-part z) 0)
         (= (imag-part z) 0)))

  (define (complex->real z)
    (make-real (real-part z)))
  
  ;; システムの他の部分へのインターフェース
  (define (tag z) (attach-tag 'complex z))
  (put 'add '(complex complex)
       (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex)
       (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex)
       (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex)
       (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'make-from-real-imag 'complex
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex
       (lambda (r a) (tag (make-from-mag-ang r a))))

  ;; 2.77追加
  (put 'real-part '(complex) real-part)
  (put 'imag-part '(complex) imag-part)
  (put 'magnitude '(complex) magnitude)
  (put 'angle '(complex) angle)

  ;; 2.79追加
  (put 'equ? '(complex complex) equ-complex?)

  ;; 2.80追加
  (put '=zero? '(complex) =zero-complex?)

  (put 'project 'complex complex->real)

  ;; 2.88追加
  (put 'negative '(complex)
       (lambda (x) (make-from-real-imag (- (real-part x)) (imag-part x))))
  
  'done)

(define (make-complex-from-real-imag x y)
  ((get 'make-from-real-imag 'complex) x y))

(define (make-complex-from-mag-ang r a)
  ((get 'make-from-mag-ang 'complex) r a))



(define (install-polynomial-package)
   ;; 内部手続き
   ;; 多項式型の表現
  (define (make-poly variable term-list)
    (cons variable term-list))
  (define (variable p) (car p))
  (define (term-list p) (cdr p))
  (define (variable? x) (symbol? x))
  (define (same-variable? v1 v2)
    (and (variable? v1) (variable? v2) (eq? v1 v2)))
  (define (=zero-poly? p)
    (=zero-terms? (term-list p)))
  
  (define (=zero-terms? term-list)
    (if (empty-termlist? term-list)
        #t
        (and (=zero? (coeff (first-term term-list)))
             (=zero-terms? (rest-terms term-list)))))
  
  ;; 項と項リストの表現
  (define (adjoin-term term term-list)
    (if (=zero? (coeff term))
        term-list
        (cons term term-list)))
  
  (define (the-empty-termlist) '())
  (define (first-term term-list) (car term-list))
  (define (rest-terms term-list) (cdr term-list))
  (define (empty-termlist? term-list) (null? term-list))

  (define (make-term order coeff) (list order coeff))
  (define (order term) (car term))
  (define (coeff term) (cadr term))
  ;; 2.88追加
  (define (negative-terms term-list)
    (if (empty-termlist? term-list)
        (the-empty-termlist)
        (let ((ft (first-term term-list))
              (lt (rest-terms term-list)))
          (adjoin-term (make-term (order ft) (negative (coeff ft)))
                       (negative-terms lt)))))

  (define (negative-poly p)
    (make-poly (variable p) (negative-terms (term-list p))))
  
  (define (add-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (add-terms (term-list p1)
                              (term-list p2)))
        (error "polys not in same var -- add-poly"
               (list p1 p2))))

  (define (sub-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (sub-terms (term-list p1)
                              (term-list p2)))
        (error "polys not in same var -- sub-poly"
               (list p1 p2))))

  (define (mul-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (mul-terms (term-list p1)
                              (term-list p2)))
        (error "polys not in same var -- mul-poly"
               (list p1 p2))))

  (define (div-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (div-terms (term-list p1)
                              (term-list p2)))
        (error "polys not in same var -- div-poly"
               (list p1 p2))))

  (define (gcd-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (gcd-terms (term-list p1)
                              (term-list p2)))
        (error "polys not in same var -- div-poly"
               (list p1 p2))))
  
  (define (add-terms l1 l2)
    (cond ((empty-termlist? l1) l2)
          ((empty-termlist? l2) l1)
          (else
           (let ((t1 (first-term l1)) (t2 (first-term l2)))
             (cond ((> (order t1) (order t2))
                    (adjoin-term
                     t1 (add-terms (rest-terms l1) l2)))
                   ((< (order t1) (order t2))
                    (adjoin-term
                     t2 (add-terms l1 (rest-terms l2))))
                   (else
                    (adjoin-term
                     (make-term (order t1)
                                (add (coeff t1) (coeff t2)))
                     (add-terms (rest-terms l1)
                                (rest-terms l2)))))))))
  
  (define (sub-terms l1 l2)
    (add-terms l1 (negative-terms l2)))
  
  (define (mul-terms l1 l2)
    (if (empty-termlist? l1)
        (the-empty-termlist)
        (add-terms (mul-term-by-all-terms (first-term l1) l2)
                   (mul-terms (rest-terms l1) l2))))

  (define (mul-term-by-all-terms t1 l)
    (if (empty-termlist? l)
        (the-empty-termlist)
        (let ((t2 (first-term l)))
          (adjoin-term
           (make-term (+ (order t1) (order t2))
                      (mul (coeff t1) (coeff t2)))
           (mul-term-by-all-terms t1 (rest-terms l))))))

  (define (div-terms l1 l2)
    (if (empty-termlist? l1)
        (list (the-empty-termlist) (the-empty-termlist))
        (let ((t1 (first-term l1))
              (t2 (first-term l2)))
          (if (> (order t2) (order t1))
              (list (the-empty-termlist) l1)
              (let ((new-c (div (coeff t1) (coeff t2)))
                    (new-o (- (order t1) (order t2))))
                (let ((rest-of-result
                       (div-terms
                        (sub-terms l1 (mul-terms (list (make-term new-o new-c)) l2))
                        l2)))
                  (list (add-terms (list (make-term new-o new-c))
                                   (car rest-of-result))
                        (cadr rest-of-result))
                  ))))))

  (define (gcd-terms a b)
    (display (list 'gcd-terms a b))
    (newline)
    (if (empty-termlist? b)
        a
        (gcd-terms b (remainder-terms a b))))

  (define (remainder-terms a b)
    (cadr (div-terms a b)))
  
  ;; システムの他の部分とのインターフェース
  (define (tag p) (attach-tag 'polynomial p))
  (put 'add '(polynomial polynomial) 
       (lambda (p1 p2) (tag (add-poly p1 p2))))
  ;; 2.88追加
  (put 'sub '(polynomial polynomial)
       (lambda (p1 p2) (tag (sub-poly p1 p2))))
  (put 'mul '(polynomial polynomial) 
       (lambda (p1 p2) (tag (mul-poly p1 p2))))
  ;; 2.91追加
  (put 'div '(polynomial polynomial)
       (lambda (p1 p2) (tag (div-poly p1 p2))))
  (put 'make 'polynomial
       (lambda (var terms) (tag (make-poly var terms))))
  (put '=zero? '(polynomial)
       (lambda (p) (=zero-poly? p)))
  ;;2.88追加
  (put 'negative '(polynomial)
       (lambda (p) (negative-poly p)))

  (put 'greatest-common-divisor '(polynomial polynomial)
       (lambda (p1 p2) (tag (gcd-poly p1 p2))))

  (trace gcd-terms)

  'done)

(define (make-polynomial var terms)
  ((get 'make 'polynomial) var terms))

(install-polar-package)
(install-rectangular-package)
(install-scheme-number-package)
(install-rational-package)
(install-complex-package)
(install-real-package)
(install-polynomial-package)

(define p1 (make-polynomial 'x '((2 1) (1 -2) (0 1))))
(define p2 (make-polynomial 'x '((2 11) (0 7))))
(define p3 (make-polynomial 'x '((1 13) (0 5))))

(define q1 (mul p1 p2))
(define q2 (mul p1 p3))
(greatest-common-divisor q1 q2)
