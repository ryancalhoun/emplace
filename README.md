[![Gem Version](https://badge.fury.io/rb/emplace.svg)](http://badge.fury.io/rb/emplace)
[![Status](https://travis-ci.org/ryancalhoun/emplace.svg?branch=master)](https://travis-ci.org/ryancalhoun/emplace)

# Emplace

Gem for cmake build settings

## Installation

Add this line to your application's Gemfile:

    gem 'emplace'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emplace

## Rakefile Usage

	require 'emplace'
	project = Emplace::Project.new 'project-name'
	project.cmake!
	project.build!
	project.test!
	# create 'dist/project-<package-name>'
	project.package!

	dependency = Emplace::Project.new 'dependency-name',
		url: 'https://dependency.org/download',
		version: 'v1.0'

	# download 'https://dependency.org/download/v1.0/dependency-name-<package-name>'
	# or locally, copy from '../dependency-name/dist/dependency-name-<package-name>'
	dependency.fetch!
	# extract to vendor/dependency-name/
	dependency.extract!

## CMake Macros

	include(Emplace)

	install_symbols(<target> [STATIC] DESTINATION <directory>)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

