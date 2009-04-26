Gem::Specification.new do |s|
	s.name = %q{ruby-feedbooks}
#	s.version =  File.read('lib/ruby-feedbooks.rb').grep(/VERSION\s*=/).first.split('=').last.gsub(/[^0-9\.]/,'')
	s.version = '0.1'
	s.date = %q{2009-04-13}
	s.authors = ["Benoit Larroque"]
	s.email = "zeta dot ben at gmail dot com"
	s.summary = %q{ruby-feedbooks is a dead simple ruby interface to feedbooks.com}
	s.homepage = %q{http://github.com/ruby-feedbooks}
	s.description = %q{ruby-feedbooks is a dead simple ruby interface to feedbooks.com}
	s.files = [ "README", "Rakefile", "lib/ruby-feedbooks.rb", "spec/ruby-feedbooks_spec.rb"]
	s.has_rdoc = true
	s.require_paths = ["lib"]
	s.add_dependency('hpricot', '>= 0.6')
end 
