# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'knife-vagrant/version'

Gem::Specification.new do |s|
  s.name         = 'knife-vagrant3'
  s.version      = Knife::Vagrant::VERSION
  s.authors      = ['Mevan Samaratunga']
  s.email        = ['mevansam@gmail.com']
  s.homepage     = 'https://github.com/mevansam/knife-vagrant3'
  s.summary      = %q{Vagrant support for Chef's knife command}
  s.description  = s.summary
  s.license      = 'Apache 2.0'

  s.files        = `git ls-files`.split("\n")

  s.add_dependency 'chef', '>= 0.10.10'
  s.add_development_dependency 'rake'

  s.require_paths = ['lib']
end
