(load "NuMongoDB")

(set mongo (NuMongoDB new))

(mongo connect)

(mongo resetDatabase)

(set sample (dict one:1
                  two:2.0
                  three:"3"
                  four:(array "zero" "one" "two" "three")))

(set bson ((NuBSON alloc) initWithObject:sample))

(mongo insert:bson)

(10 times:
    (do (i)
        (set object (dict i:i name:(+ "mongo-" i) (+ "key-" i) sample))
        (set bson ((NuBSON alloc) initWithObject:object))
        (mongo insert:bson)))

(set cursor (mongo find))

(while (cursor next)
       (set bson (cursor currentBSON))
       (set object (bson objectValue))
       (puts (object description)))

