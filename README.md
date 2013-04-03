ObjCMongoDB is a Mac OS and iOS library for [MongoDB][] and [BSON][] based on
the [10gen C driver][mongo-c-driver].

## Latest release

The latest release is v0.9.6.

 -   Based on v0.7.1 of the driver
 -   Now supports iOS!
 -   Works under OS X 10.6 – 10.8 and iOS 6.1 (probably early versions too)
 -   Works both with and without support for ARC
 
```sh
git checkout v0.9.6     # since master may be a work in process
```

See what's changed in [History][].

## Getting started

Refer to the installation instructions and sample code on the
[wiki][]:

 -   [Getting started using ObjCMongoDB in your Mac OS project][GettingStarted]
 -   [The basics of using ObjCMongoDB][TheBasics]

## Features

 -   Simple BSON encoding and decoding, using dictionaries.

 -   Built-in support for arrays, dictionaries, embedded objects, strings,
     numbers, dates, object IDs, and the miscellaneous MongoDB types.

 -   More complex encoding and decoding based on NSCoder's keyed coding
     scheme. A robust delegate interface lets you implement encoding and
     decoding entirely outside the model classes if necessary.
   
 -   Automatically encodes and decodes Core Data entities. Using the coder's
     delegate interface you can customize the default behavior, or simply
     implement alternate behavior it in the entity class.

 -   Aims to feel Cocoa-like, not Mongo-like. For example, method names in
     MongoKeyedPredicate and MongoUpdateRequest are natural in Cocoa, though
     they don't conform to the underlying Mongo keywords.

## License

Sources copyright Paul Melnikow, 10gen, Matthew Gallagher, and other
contributors.

Unless otherwise specified in a source file, sources in this repository are
published under the terms of the Apache License version 2.0, a copy of which is
in this repository as APACHE-2.0.txt.

## Acknowledgements

 -  Originally based on [NuMongoDB][] by Tim Burks: Copyright 2010 Neon Design Technology, Inc.
 -  Includes enhancements by [Diederik Hoogenboom][] and [Rob Elkin][]
 -  [Official MongoDB C driver][mongo-c-driver]: Copyright 2009, 2010 10gen Inc.
 -  [OrderedDictionary][] by Matt Gallagher: Copyright 2008 Matt Gallagher

[BSON]: http://bsonspec.org/
[MongoDB]: http://www.mongodb.org/
[mongo-c-driver]: https://github.com/mongodb/mongo-c-driver
[History]: HISTORY.md
[Wiki]: https://github.com/noa--/ObjCMongoDB/wiki
[GettingStarted]: https://github.com/noa--/ObjCMongoDB/wiki/GettingStarted
[TheBasics]: https://github.com/noa--/ObjCMongoDB/wiki/TheBasics
[NuMongoDB]: https://github.com/timburks/NuMongoDB
[Diederik Hoogenboom]: https://github.com/dhoogenb/NuMongoDB
[Rob Elkin]: https://github.com/robelkin/NuMongoDB
[OrderedDictionary]: http://cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html

