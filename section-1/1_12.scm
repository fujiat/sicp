(define (p n k)
  (if (or (= n k) (= k 1))
      1
      (+ (p (- n 1) (- k 1))
         (p (- n 1) k))))

;;(p 5 3)
;;(+ (p 4 2) (p 4 3))
;;(+ (+ (p 3 1) (p 3 2)) (+ (p 3 2) (p 3 3)))
;;(+ (+ 1 (+ (p 2 1) (p 2 2))) (+ (+ (p 2 1) (p 2 2)) 1))
;;(+ (+ 1 (+ 1 1)) (+ (+ 1 1) 1))
;; 6