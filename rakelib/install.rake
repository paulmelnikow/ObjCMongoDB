# origin: https://github.com/paulmelnikow/pod-template-rake
#
# references:
# * http://www.objc.io/issue-6/travis-ci.html
# * https://github.com/supermarin/xcpretty#usage


task :install_pods do
  raise unless system "pod install --project-directory=Example"
end

desc "Install development dependencies"
task :install => :install_pods do
  puts
  puts "Installing xcpretty gem with sudo."
  puts
  raise unless system "sudo -k gem install xcpretty"
end

desc "Run from .travis.yml to install dependencies on Travis"
task :install_for_ci do
  # Uncomment if Pods/ is in .gitignore
  raise unless system "gem install cocoapods --no-rdoc --no-ri --no-document --quiet" # Since Travis is not always on latest version
  Rake::Task['install_pods'].invoke

  raise unless system "gem install xcpretty --no-rdoc --no-ri --no-document --quiet"
end
