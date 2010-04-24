;; test_access.nu
;;  tests for NuMongoDB database access.
;;
;;  Copyright (c) 2010 Tim Burks, Neon Design Technology, Inc.
(load "NuMongoDB")

(class TestAccess is NuTestCase
     
     (- testSession is
        
        (set database "test")
        (set collection "sample")
        (set path (+ database "." collection))
        
        (set mongo (NuMongoDB new))
        
        (set connected (mongo connectWithOptions:nil))
        (assert_equal 0 connected)
        (unless (eq connected 0)
                (puts "could not connect to database. Is mongod running?"))
        
        (if (eq connected 0)
            (mongo dropCollection:collection inDatabase:database)
            
            (set sample (array "s" "a" "m" "p" "l" "e"))
            (5 times:
               (do (i)
                   (5 times:
                      (do (j)
                          (set object (dict i:i
                                            j:j
                                            name:(+ "mongo-" i "-" j)
                                            (+ "key-" i "-" j) sample))
                          (set bson ((NuBSON alloc) initWithDictionary:object))
                          (mongo insert:bson intoCollection:path)))))
            
            ;; test query
            (set cursor (mongo find:(dict $where:"this.i == 3") inCollection:path))
            (set matches 0)
            (while (cursor next)
                   (set matches (+ matches 1))
                   (set bson (cursor currentBSON))
                   (set object (bson dictionaryValue))
                   (assert_equal 3 (object i:)))
            (assert_equal 5 matches)
            
            ;; test update
            (mongo update:((NuBSON alloc) initWithDictionary:(dict "$set" (dict k:456)))
                   inCollection:path
                   withCondition:((NuBSON alloc) initWithDictionary:(dict i:3))
                   insertIfNecessary:YES
                   updateMultipleEntries:YES)
            
            ;; verify update results and a few other saved values
            (set cursor (mongo find:(dict i:3) inCollection:path))
            (while (cursor next)
                   (set bson (cursor currentBSON))
                   (set object (bson dictionaryValue))
                   (assert_equal 456 (object k:))
                   (assert_equal (+ "mongo-" (object i:) "-" (object j:)) (object name:))
                   (assert_equal 6 ((object (+ "key-" (object i:) "-" (object j:))) count)))
            (set cursor (mongo find:(dict i:2) inCollection:path))
            (while (cursor next)
                   (set bson (cursor currentBSON))
                   (set object (bson dictionaryValue))
                   (assert_equal nil (object k:))))))

