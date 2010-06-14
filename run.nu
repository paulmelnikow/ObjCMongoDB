(load "NuMongoDB")

(set collection "test.sample")

(set mongo (NuMongoDB new))

(puts "connecting")
(mongo connectWithOptions:(dict host:"67.23.47.34"))
(puts "connected")

(mongo dropCollection:"sample" inDatabase:"test")

(puts "ok")

(set sample (dict one:1
                  two:2.0
                  three:"3"
                  four:(array "zero" "one" "two" "three")))

(set bson ((NuBSON alloc) initWithDictionary:sample))

(mongo insert:bson intoCollection:collection)
(puts "ok")

(10 times:
    (do (i)
        (10 times:
            (do (j)
                (set object (dict i:i j:j name:(+ "mongo-" i "-" j) (+ "key-" i "-" j) sample))
                (set bson ((NuBSON alloc) initWithDictionary:object))
                (mongo insert:bson intoCollection:collection)))))

(set cursor (mongo find:(dict $where:"this.i == 3") inCollection:collection))
(while (cursor next)
       (set bson (cursor currentBSON))
       (set object (bson dictionaryValue))
       (puts (object description)))

(puts "updating")
(mongo update:((NuBSON alloc) initWithDictionary:(dict "$set" (dict k:456)))
       inCollection:collection
       withCondition:((NuBSON alloc) initWithDictionary:(dict i:3))
       insertIfNecessary:YES
       updateMultipleEntries:YES)

(set cursor (mongo find:(dict i:3) inCollection:collection))
(while (cursor next)
       (puts "iterating")
       (set bson (cursor currentBSON))
       (set object (bson dictionaryValue))
       (puts (object description)))

(puts "ok")

