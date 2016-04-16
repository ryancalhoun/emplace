Gem::Specification.new {|s|
	s.name = 'emplace'
	s.version = '0.3.2'
	s.licenses = ['MIT']
	s.summary = 'Gem for cmake build settings'
	s.description = 'Keeps settings for running cmake builds on Travis-CI and AppVeyor.'
	s.homepage = 'https://github.com/ryancalhoun/emplace'
	s.authors = ['Ryan Calhoun']
	s.email = ['ryanjamescalhoun@gmail.com']
  
	s.files = [
    'bin/emplace',
    'lib/emplace.rb',
    'lib/emplace/app.rb',
    'modules/Emplace.cmake',
    'modules/unix/Emplace.cmake',
    'modules/win32/Emplace.cmake',
    'LICENSE',
    'README.md'
  ]
  s.executables = [
    'emplace'
  ]
	s.test_files = ['test/emplace-test.rb', 'Rakefile']
}

