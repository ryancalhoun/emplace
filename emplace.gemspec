Gem::Specification.new {|s|
	s.name = 'emplace'
	s.version = '0.3.2'
	s.licenses = ['MIT']
	s.summary = 'Gem for cmake build settings'
	s.description = 'Keeps settings for running cmake builds on Travis-CI and AppVeyor.'
	s.homepage = 'https://github.com/ryancalhoun/emplace'
	s.authors = ['Ryan Calhoun']
	s.email = ['ryanjamescalhoun@gmail.com']
  
	s.files = Dir["{bin,lib,modules}/**/*"] + %w(LICENSE README.md)

  s.executables = s.files.grep(/^bin\//).map {|f| File.basename f}
	s.test_files = Dir["{test/**/*"] + %w(Rakefile)
}

