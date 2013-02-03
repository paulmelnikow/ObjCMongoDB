# TODO - C Driver 0.5 to 0.7.1

## Test cases

 - generateFuzzUsingBlock
 - generateIncrementUsingBlock

## Other changes

 -  ~~BSONObjectID instance method for MONGO_EXPORT time_t bson_oid_generated_time( bson_oid_t *oid );~~
 -  ~~BSONObjectID class method for MONGO_EXPORT void bson_set_oid_fuzz( int ( *func )( void ) );~~
 -  ~~BSONObjectID class method for MONGO_EXPORT void bson_set_oid_inc( int ( *func )( void ) );~~


## 0.7.1
2013-1-7

Fixes

* ~~collections with one character name~~
* ~~set socket option NOSIGPIPE for Mac OS X~~
* ~~reorganize env packaging to ease build for the R driver~~
* ~~add bcon to library build for Scons~~
* ~~package build support with DESTDIR and PREFIX~~

## 0.7
2012-11-19
** API CHANGE **

~~In version 0.7, mongo_client and mongo_replica_set_client are the connection functions,
replacing the deprecated functions mongo_connect and mongo_replset_connect, respectively.~~
The mongo_client and mongo_replica_set_client functions now have a default write concern
specifying the acknowledgement of writes.
Please see the Write Concern document for explicit details.
~~The term "replica_set" replaces "replset" consistently,
and the functions containing "replset" are deprecated.~~

~~BCON (BSON C Object Notation) provides JSON-like (or BSON-like) initializers
in C and readable, and maintainable data-driven definition of BSON documents.~~

Other features and fixes include:

* ~~support for Unix domain sockets~~
* ~~three memory leak fixes in library code~~
* ~~proper cursor termination at the end of a set of large documents~~
* mongo_get_primary initialization to avoid memory overrun
* ~~Mac dynamic library linking~~
* ~~example.c compilation~~
* ~~various other minor fixes since 2012-6-28~~

## 0.6
2012-6-3
** API CHANGE **

Version 0.6 supports write concern. This involves a backward-breaking
API change, as the write functions now take an optional write_concern
object.

The driver now also supports the MONGO_CONTINUE_ON_ERROR flag for
batch inserts.

The new function prototypes are as follows:

* int mongo_insert( mongo *conn, const char *ns, const bson *data,
      mongo_write_concern *custom_write_concern );

* int mongo_insert_batch( mongo *conn, const char *ns,
    const bson **data, int num, mongo_write_concern *custom_write_concern );

* int mongo_update( mongo *conn, const char *ns, const bson *cond,
    const bson *op, int flags, mongo_write_concern *custom_write_concern,
    int flags );

* int mongo_remove( mongo *conn, const char *ns, const bson *cond,
    mongo_write_concern *custom_write_concern );

* Allow DBRefs (i.e., allows keys $ref, $id, and $db)
* Added mongo_create_capped_collection().
* ~~Fixed some bugs in the SCons and Makefile build scripts.~~
* ~~Fixes for SCons and Makefile shared library install targets.~~
* ~~Other minor bug fixes.~~

## 0.5.2
2012-5-4

* Validate collection and database names on insert.
* Validate insert limits using max BSON size.
* ~~Support getaddrinfo and SO_RCVTIMEO and SO_SNDTIMEO on Windows.~~
* Store errno/WSAGetLastError() on errors.
* ~~Various bug fixes and refactorings.~~
* Update error reporting docs.

## 0.5.1

* ~~Env for POSIX, WIN32, and standard C.~~
* ~~Various bug fixes.~~