(load "NuMongoDB")

(set collection "test.sample")

(set mongo (NuMongoDB new))

(mongo connect)

(mongo dropCollection:"sample" inDatabase:"test")

(set sample (dict one:1
                  two:2.0
                  three:"3"
                  four:(array "zero" "one" "two" "three")))

(set bson ((NuBSON alloc) initWithDictionary:sample))

(mongo insert:bson intoCollection:collection)

(1000 times:
    (do (i)
        (set object (dict i:i name:(+ "mongo-" i) (+ "key-" i) sample))
        (set bson ((NuBSON alloc) initWithDictionary:object))
        (mongo insert:bson intoCollection:collection)))

(set cursor (mongo find:(dict $where:"this.i == 401") inCollection:collection))

(while (cursor next)
       (set bson (cursor currentBSON))
       (set object (bson dictionaryValue))
       (puts (object description)))

(puts "ok")

