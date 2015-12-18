require 'rake/testtask'

Rake::TestTask.new {|t|
	t.test_files = FileList['test/**/*est.rb']
}

desc 'Run tests'
task :default => :test

# experiment...
require_relative './lib/emplace'
task :fetch do
  em = Emplace::Project.new('cppunit')
  url = 'https://github.com/ryancalhoun/cppunit/releases/download/v1.14.0-7/'

  em.fetch! url
  em.extract!
end
