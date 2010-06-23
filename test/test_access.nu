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
            ;; start clean
            (mongo dropCollection:collection inDatabase:database)
            
            ;; insert some sample values
            (set sample (array "s" "a" "m" "p" "l" "e"))
            (5 times:
               (do (i)
                   (5 times:
                      (do (j)
                          (set object (dict i:i
                                            j:j
                                            name:(+ "mongo-" i "-" j)
                                            (+ "key-" i "-" j) sample))
                          (mongo insertObject:object intoCollection:path)))))
            
            ;; test counts
            (set count (mongo countWithCondition:nil inCollection:collection inDatabase:database))
            (assert_equal 25 count)
            (set count (mongo countWithCondition:(dict i:1) inCollection:collection inDatabase:database))
            (assert_equal 5 count)
            
            ;; REPEAT: test counts using the run command
            (set count ((mongo runCommand:(dict count:"sample") inDatabase:"test") n:))
            (assert_equal 25 count)
            (set count ((mongo runCommand:(dict count:"sample" query:(dict i:1)) inDatabase:"test") n:))
            ;; this test fails with MongoDB v1.4 (Debian) and works with v1.4.1 (Mac OS 10.6)
            ;; apparently because the query option is not supported in v1.4
            (assert_equal 5 count)
            
            ;; test a query using the $where operator
            (set cursor (mongo find:(dict $where:"this.i == 3") inCollection:path))
            (set matches 0)
            (while (cursor next)
                   (set matches (+ matches 1))
                   (set object (cursor currentObject))
                   (assert_equal 3 (object i:)))
            (assert_equal 5 matches)
            
            ;; test a qualified update
            (mongo updateObject:(dict "$set" (dict k:456))
                   inCollection:path
                   withCondition:(dict i:3)
                   insertIfNecessary:YES
                   updateMultipleEntries:YES)
            
            ;; make sure we changed the entries we wanted to change
            (set cursor (mongo find:(dict i:3) inCollection:path))
            (while (cursor next)
                   (set object (cursor currentObject))
                   (assert_equal 456 (object k:))
                   ;; while we're iterating, check some other inserted values
                   (assert_equal (+ "mongo-" (object i:) "-" (object j:)) (object name:))
                   (assert_equal 6 ((object (+ "key-" (object i:) "-" (object j:))) count)))
            ;; and sanity-check that we didn't affect anything else
            (set cursor (mongo find:(dict i:2) inCollection:path))
            (while (cursor next)
                   (set object (cursor currentObject))
                   (assert_equal nil (object k:)))
            
            ;; test update, this time we update with a condition on two keys
            (mongo updateObject:(dict "$set" (dict k:999))
                   inCollection:path
                   withCondition:(dict i:2 j:2)
                   insertIfNecessary:YES
                   updateMultipleEntries:YES)
            ;; make sure we changed the entry we wanted to change
            (set cursor (mongo find:(dict i:2 j:2) inCollection:path))
            (while (cursor next)
                   (set object (cursor currentObject))
                   (assert_equal 999 (object k:)))
            ;; and sanity-check that we didn't affect anything else
            (set cursor (mongo find:(dict i:1 j:2) inCollection:path))
            (while (cursor next)
                   (set object (cursor currentObject))
                   (assert_equal nil (object k:)))
            
            ;; findOne
            (set one (mongo findOne:(dict i:1 j:2) inCollection:path))
            (assert_equal nil (object k:))
            (assert_equal 1 (object i:))
            (assert_equal 2 (object j:))
            
            ;; remove one
            (mongo removeWithCondition:(dict i:1 j:2) fromCollection:path)
            (set one (mongo findOne:(dict i:1 j:2) inCollection:path))
            (assert_equal nil one)
            
            (set count (mongo countWithCondition:nil inCollection:collection inDatabase:database))
            (assert_equal 24 count)
            
            ;; remove everything, but first verify that we have some entries to delete
            (set one (mongo findOne:nil inCollection:path))
            (assert_not_equal nil one)
            (mongo removeWithCondition:nil fromCollection:path)
            (set one (mongo findOne:nil inCollection:path))
            (assert_equal nil one)
            
            ;; clean up
            (mongo dropCollection:collection inDatabase:database)))
     
     (- testFindArray is
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
            
            ;; insert some sample values
            
            (1000 times:
                  (do (i)
                      (set object (dict i:i i2:(* i i)))
                      (mongo insertObject:object intoCollection:path)))
            
            (set result (mongo findArray:nil inCollection:path returningFields:nil numberToReturn:10 numberToSkip:10))
            (assert_equal 10 (result count))
            
            (mongo dropCollection:collection inDatabase:database))))
