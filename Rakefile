require 'rake/testtask'
require'fileutils'

desc 'Clean build artifacts'
task :clean do
  Dir['emplace-*.gem'].each {|file|
    FileUtils.rm_f file
  }
end

desc 'Build gem'
task :build => [:clean] do
  sh 'gem build emplace.gemspec'
end

desc 'Perform local install'
task :install => [:build] do
  sh "sudo gem install #{Dir['emplace-*.gem'].first}"
end

Rake::TestTask.new {|t|
	t.test_files = FileList['test/**/*est.rb']
}

desc 'Run tests'
task :default => :test

