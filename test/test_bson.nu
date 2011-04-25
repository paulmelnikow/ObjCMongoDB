;; test_bson.nu
;;  tests for NuBSON representation.
;;
;;  Copyright (c) 2010 Tim Burks, Neon Design Technology, Inc.

(load "NuMongoDB")

(class TestBSON is NuTestCase
     
     (- testRoundtrip is
        (set x (dict a:"a"
                     b:"bee"
                     c:123
                     d:(NSDate date)
                     e:123.456
                     f:(dict a:(array 1 2 3))
                     g:(NSData dataWithContentsOfFile:"mongoleaf.png")
                     h:nil))
        (set bson (NuBSON bsonWithDictionary:x))
        (set data (bson dataRepresentation))
        (set bson2 (NuBSON bsonWithData:data))
        (set y (bson2 dictionaryValue))
        (assert_equal (x a:) (y a:))
        (assert_equal (x b:) (y b:))
        (assert_equal (x c:) (y c:))
        ;; bson only stores times with millisecond precision
        (assert_in_delta ((x d:) timeIntervalSinceReferenceDate)
             ((y d:) timeIntervalSinceReferenceDate)
             0.001)
        (assert_equal (x e:) (y e:))
        (assert_equal (x f:) (y f:))
        (assert_equal (x g:) (y g:))
        (assert_equal (x h:) (y h:))
        
        ;; now stay as bson
        (set z (NuBSON bsonWithDictionary:y))
        (assert_equal (y a:) (z a:))
        (assert_equal (y b:) (z b:))
        (assert_equal (y c:) (z c:))
        (assert_equal (y d:) (z d:))
        (assert_equal (y e:) (z e:))
        ;; expand this one since (z f:) is a bson object
        (assert_equal ((y f:) a:) ((z f:) a:))
        (assert_equal (y g:) (z g:))
        (assert_equal (y h:) (z h:)))
     
     (- testOIDs is
        (10 times:
            (do (i)
                (set id1 ((NuBSONObjectID objectID)))
                (set id2 ((NuBSONObjectID alloc)
                          initWithData:(id1 dataRepresentation)))
                (assert_equal id1 id2)
                
                (set id3 (NuBSONObjectID new))
                (set id4 (NuBSONObjectID new))
                
                (set d (dict id1 123 id3 456))
                (assert_equal 123 (d id1))
                (assert_equal 123 (d id2))
                (assert_equal 456 (d id3))
                (assert_equal 456 (d id4)))))
     
     (- testCode is
        (set code '(do (x) (+ x 1)))
        (set bson (NuBSON bsonWithDictionary:(dict code:code)))
        (set code2 ((bson dictionaryValue) code:))
        (assert_equal code code2)
        (assert_equal 2 (eval (list code2 1)))))


