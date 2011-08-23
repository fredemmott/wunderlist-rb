# -*- encoding: utf-8 -*-
require 'rake'

Gem::Specification.new do |s|
  s.name          = 'wunderlist-rb'
  s.version       = '0.0.1'
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Fred Emmott']
  s.email         = ['gems@fredemmott.co.uk']
  s.require_paths = ['lib']
  s.homepage      = 'https://github.com/fredemmott/wunderlist-rb'
  s.summary       = 'WIP gem for interacting with Wunderlist'
  s.description   = "I'll find something to put here"
  s.files         = FileList[
    'COPYING',
    'README.rdoc',
    'lib/**/*.rb',
  ].to_a

  s.add_dependency 'curb'
end
