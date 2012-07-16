require 'rubygems'
begin
  require 'rake'
  #require 'jeweler'
  require 'rspec/core'
  require 'rspec/core/rake_task'
  #require 'yard'
rescue LoadError => e
  $stderr.puts e, "Run `gem install bundler && bundle install` to install missing gems."
  exit 1
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec