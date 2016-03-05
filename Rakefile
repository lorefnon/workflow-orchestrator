require 'rubygems'
require 'rake/testtask'
require 'rdoc/task'

require 'bundler'
Bundler.setup

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  task :default => :appraisal
else
  task :default => [:test]
end

require 'rake'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.verbose = true
  t.warning = true
  t.test_files = FileList['test/*_test.rb'] + FileList['test/new_versions/*_test.rb']
end

Rake::TestTask.new do |t|
  t.name = 'test_without_new_versions'
  t.libs << 'test'
  t.verbose = true
  t.warning = true
  t.pattern = 'test/*_test.rb'
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include("lib/**/*.rb")
  rdoc.options << "-S"
end

