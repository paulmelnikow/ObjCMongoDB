;; test_bson.nu
;;  tests for NuBSON representation.
;;
;;  Copyright (c) 2010 Tim Burks, Neon Design Technology, Inc.

(load "NuMongoDB")

(class TestBSON is NuTestCase
     
     (- testRoundtrip is
        (set x (dict a:"a" b:"bee" c:123 d:(NSDate date) e:123.456 f:(dict a:(array 1 2 3))))
        (set data (x BSONRepresentation))
        (set y (data BSONValue))
        (assert_equal (x a:) (y a:))
        (assert_equal (x b:) (y b:))
        (assert_equal (x c:) (y c:))
        ;; bson only stores times with millisecond precision
        (assert_in_delta ((x d:) timeIntervalSinceReferenceDate)
             ((y d:) timeIntervalSinceReferenceDate)
             0.001)
        (assert_equal (x e:) (y e:))
        (assert_equal (x f:) (y f:))
        
        (set data (y BSONRepresentation))
        (set z (data BSONValue))
        (assert_equal (y a:) (z a:))
        (assert_equal (y b:) (z b:))
        (assert_equal (y c:) (z c:))
        (assert_equal (y d:) (z d:))
        (assert_equal (y e:) (z e:))
        (assert_equal (y f:) (z f:))
        
        
        ))
