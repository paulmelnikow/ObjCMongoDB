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
        (assert_equal (y h:) (z h:))))
