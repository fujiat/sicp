(define false #f)

(define (make-table same-key?)
  (let ((local-table (list '*table*)))
    (define (assoc key records)
      (cond ((null? records) false)
            ((same-key? key (caar records)) (car records))
            (else (assoc key (cdr records)))))
    (define (lookup key-list)
      (lookup-iter key-list local-table))
    (define (lookup-iter key-list local-table)
      (if (null? key-list)
          false
          (let ((subtable (assoc (car key-list) (cdr local-table))))
            (if subtable
                (if (null? (cdr key-list))
                    (cdr subtable)
                  (lookup-iter (cdr key-list) subtable))
                false))))
    (define (insert! key-list value)
      (insert-iter! key-list value local-table))
    (define (insert-iter! key-list value local-table)
      (if (null? key-list)
          false
          (let ((subtable (assoc (car key-list) (cdr local-table))))
            (if subtable
                (if (null? (cdr key-list))
                    (set-cdr! subtable value)
                    (insert-iter! (cdr key-list) value subtable))
                (set-cdr! local-table
                          (cons (insert-iter key-list value)
                                (cdr local-table))))))
      'ok)
    (define (insert-iter key-list value)
      (if (null? (cdr key-list))
          (cons (car key-list) value)
          (list (car key-list) (insert-iter (cdr key-list) value))))
    (define (dispatch m)
      (cond ((eq? m 'lookup-proc) lookup)
            ((eq? m 'insert-proc!) insert!)
            (else (error "Unknown operation -- TABLE" m))))
    dispatch))

(define tb (make-table equal?))
(define lookup (tb 'lookup-proc))
(define insert! (tb 'insert-proc!))

(insert! '(japan tokyo 2009/2/13) 20.1)
(insert! '(japan osaka 2009/2/13) 22.0)
(insert! '(usa newyork 2009/2/13) 14.5)
(lookup '(japan tokyo 2009/2/13))
(lookup '(japan osaka 2009/2/13))
