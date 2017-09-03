(load "./stream")

(define (merge-weighted pairs1 pairs2 weight)
  (cond ((stream-null? (stream-car pairs1)) pairs2)
        ((stream-null? (stream-car pairs2)) pairs1)
        (else
         (let ((p1car (stream-car pairs1))
               (p2car (stream-car pairs2)))
           (if (< (weight p1car) (weight p2car))
	       (cons-stream p1car (merge-weighted (stream-cdr pairs1) pairs2 weight))
	       (cons-stream p2car (merge-weighted pairs1 (stream-cdr pairs2) weight)))))))

(define (weighted-pairs s t weight)
  (cons-stream
   (list (stream-car s) (stream-car t))
   (merge-weighted
    (stream-map (lambda (x) (list (stream-car s) x))
                (stream-cdr t))
    (weighted-pairs (stream-cdr s) (stream-cdr t) weight)
    weight)))

;; a
(define (add-pairs-weight pair)
  (+ (car pair) (cadr pair)))

(stream-head (weighted-pairs integers integers add-pairs-weight) 10)

;;b
(define (add-pairs-weight2 pair)
  (let ((i (car pair))
	(j (cadr pair)))
    (+ (* 2 i)
       (* 3 j)
       (* 5 i j))))

(define integers-no-remainder-2-3-5
  (stream-filter (lambda (x)
		   (not (and (= 0 (remainder x 2))
			     (= 0 (remainder x 3))
			     (= 0 (remainder x 5)))))
		 integers))

(stream-head (weighted-pairs integers-no-remainder-2-3-5 integers-no-remainder-2-3-5 add-pairs-weight2) 10)
