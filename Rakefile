require 'rubygems'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |t|
	t.warning = true
	t.rcov = true
end


desc "Run all examples"
Spec::Rake::SpecTask.new('all_spec') do |t|
	  t.spec_files = FileList['spec/*_spec.rb']
	  t.spec_opts = ["--format","specdoc"]
end

task :default => [:all_spec]
