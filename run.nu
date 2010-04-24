(load "NuMongoDB")

(set mongo (NuMongoDB new))

(mongo connect)

(mongo resetDatabase)

(mongo loadDB)

(mongo readDB)
