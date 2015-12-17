[![Gem Version](https://badge.fury.io/rb/emplace.svg)](http://badge.fury.io/rb/emplace)

# Emplace

Gem for cmake build settings

## Installation

Add this line to your application's Gemfile:

    gem 'emplace'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emplace

## Usage

	require 'emplace'
	project = Emplace.new 'project-name'
	project.cmake!
	project.build!
	project.test!
	project.package!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

