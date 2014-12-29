# origin: https://github.com/paulmelnikow/pod-template-rake

scheme_args = "-workspace Example/#{$pod_name}.xcworkspace -scheme #{$pod_name}-Example"

desc "Run tests on the iOS Simulator"
task :test do
  raise unless system "bash -c 'set -o pipefail && xcodebuild test #{scheme_args} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO | xcpretty -c'"
end

desc "Clean build"
task :clean do
  raise unless system "xcodebuild clean #{scheme_args}"
end
