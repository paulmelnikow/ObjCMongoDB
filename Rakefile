namespace :test do
  desc "Run the BSON Tests for Mac OS X"
  task :bson_osx do
    $bson_osx_success = system("xcodebuild test -workspace Xcode/ObjCMongoDB.xcworkspace -scheme BSONTests")
  end

  desc "Run the BSON Tests for Mac OS X under manual retain-release"
  task :bson_osx_no_arc do
    $bson_osx_no_arc_success = system("xcodebuild test -workspace Xcode/ObjCMongoDB.xcworkspace -scheme BSONTests-no-arc")
  end

  desc "Run the BSON Tests for iOS"
  task :bson_ios do
    $bson_ios_success = system("xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 7 Plus,OS=10.2' -workspace Xcode/ObjCMongoDB.xcworkspace -scheme BSONTests-iOS")
  end

  desc "Run the Mongo Tests for Mac OS X"
  task :mongo_osx do
    $mongo_osx_success = system("xcodebuild test -workspace Xcode/ObjCMongoDB.xcworkspace -scheme MongoTests")
  end

  desc "Run the Mongo Tests for Mac OS X under manual retain-release"
  task :mongo_osx_no_arc do
    $mongo_osx_no_arc_success = system("xcodebuild test -workspace Xcode/ObjCMongoDB.xcworkspace -scheme MongoTests-no-arc")
  end

  desc "Run the Mongo Tests for iOS"
  task :mongo_ios do
    $mongo_ios_success = system("xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 7 Plus,OS=10.2' -workspace Xcode/ObjCMongoDB.xcworkspace -scheme MongoTests-iOS")
  end
end

desc "Run the BSON and Mongo Tests for Mac OS X and iOS"
task :test => ['test:bson_osx', 'test:bson_osx_no_arc', 'test:bson_ios',
               'test:mongo_osx', 'test:mongo_osx_no_arc', 'test:mongo_ios'] do
  puts "\033[0;31m!! BSON tests failed on Mac OS" unless $bson_osx_success
  puts "\033[0;31m!! BSON tests failed on Mac OS under manual retain-release" unless $bson_osx_no_arc_success
  puts "\033[0;31m!! BSON tests failed on iOS" unless $bson_ios_success
  puts "\033[0;31m!! Mongo tests failed on Mac OS" unless $mongo_osx_success
  puts "\033[0;31m!! Mongo tests failed on Mac OS under manual retain-release" unless $mongo_osx_no_arc_success
  puts "\033[0;31m!! Mongo tests failed on iOS" unless $mongo_ios_success
  if $bson_osx_success && $bson_osx_no_arc_success && $bson_ios_success &&
    $mongo_osx_success && $mongo_osx_no_arc_success && $mongo_ios_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit(-1)
  end
end

task :default => 'test'
