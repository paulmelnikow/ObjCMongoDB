#
# IMPORTANT
#
# This development branch depends on unreleased development versions of
# mongo-c-driver and libbson.
#
# CocoaPods does not allow pods to depend on pods from git, so you need
# to pull them in from your Podfile instead:
# 
# pod 'ObjCMongoDB', :git => 'https://github.com/paulmelnikow/ObjCMongoDB', :branch => 'libmongoc'
# pod 'ObjCBSON', :git => 'https://github.com/paulmelnikow/ObjCBSON'
# pod 'libbson', :git => 'https://github.com/paulmelnikow/libbson', :branch => 'podspec-1'
# pod 'mongo-c-driver', :git => 'https://github.com/paulmelnikow/mongo-c-driver-1', :branch => 'podspec'
#
# Note the libbson and mongo-c-driver forks, which you need to use
# because the 10gen repositories do not contain podspecs at this time.
# These forks are unstable and are for development purposes only.
#

Pod::Spec.new do |s|
  s.name         = 'ObjCMongoDB'
  s.version      = '1.0.0-dev'
  s.summary      = 'Mac OS and iOS library for MongoDB and BSON.'
  s.description  = <<-DESC
                   Mac OS and iOS library for MongoDB and BSON.
                    - Simple BSON encoding and decoding, using dictionaries.
                    - Built-in support for arrays, dictionaries, embedded objects, strings, numbers, dates, object IDs, and the miscellaneous MongoDB types.
                    - More complex encoding and decoding based on NSCoder's keyed coding scheme. A robust delegate interface lets you implement encoding and decoding entirely outside the model classes if necessary.
                    - Automatically encodes and decodes Core Data entities. Using the coder's delegate interface you can customize the default behavior, or simply implement alternate behavior it in the entity class.
                    - Aims to feel Cocoa-like, not Mongo-like. For example, method names in MongoKeyedPredicate and MongoUpdateRequest are natural in Cocoa, though they don't conform to the underlying Mongo keywords.
                    DESC
  s.homepage     = 'https://github.com/paulmelnikow/ObjCMongoDB'
  s.license      = 'Apache'
  s.author       = { "Paul Melnikow" => "github@paulmelnikow.com" }
  s.source       = { :git => 'https://github.com/paulmelnikow/ObjCMongoDB.git',
                     :tag => "v#{s.version}" }
  
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.6'
  s.requires_arc = true

  s.source_files = 'Pod'
  s.private_header_files = 'Pod/*-private.h'

#  s.dependency 'ObjCBSON', '~> 0.1'
#  s.dependency 'mongo-c-driver', '~> 1.1.0'
end
