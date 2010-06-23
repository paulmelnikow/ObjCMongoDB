(load "NuMongoDB")

(set collection "geo.places")

(set mongo (NuMongoDB new))

(puts "connecting")
(mongo connectWithOptions:(dict host:"127.0.0.1"))
(puts "connected")

(set count (mongo count:nil inCollection:"places" inDatabase:"geo"))

(puts count)

(if YES
    (puts "building")
    ;; rebuild the place database
    (mongo dropCollection:"places" inDatabase:"geo")
    (set N 200)
    (N times:
       (do (i)
           ;(set latitude (* i (/ 180 N)))
           (N times:
              (do (j)
                  ;(set longitude (* j (/ 180 N)))
                  (set latitude (/ (% (NuMath random) 180000) 1000))
                  (set longitude (/ (% (NuMath random) 180000) 1000))
                  (set place (dict name:(+ "location-" i "-" j)
                                   location:(dict latitude:latitude longitude:longitude)))
                  (mongo insert:place intoCollection:collection)))))
    (mongo ensureCollection:"geo.places" hasIndex:(dict location:"2d") withOptions:0))

;; search the place database
(puts "querying")
(1 times:(do (i)
             (set cursor (mongo find:(dict location:(dict $near:(dict latitude:70 longitude:80))) inCollection:"geo.places"))
             (set i 0)
             (while (and (cursor next) (< i 10))
                    (set object (cursor currentObject))
                    (puts (object description))
                    (set i (+ i 1)))
             ))