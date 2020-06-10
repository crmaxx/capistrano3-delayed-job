# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/delayed-job/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano3-delayed-job'
  spec.version = Capistrano::DELAYED_JOB_VERSION
  spec.authors = ['Maxim Zhukov']
  spec.email = ['crmaxx@gmail.com']
  spec.description = %q{DelayedJob integration for Capistrano 3}
  spec.summary = %q{DelayedJob integration for Capistrano}
  spec.homepage = 'https://github.com/crmaxx/capistrano3-delayed-job'
  spec.license = 'MIT'

  spec.required_ruby_version     = '>= 1.9.3'

  spec.files = `git ls-files`.split($/)
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.7'
  spec.add_dependency 'capistrano-bundler'
  spec.add_dependency 'delayed_job' , '~> 4.1'
  spec.post_install_message = %q{
    All plugins need to be explicitly installed with install_plugin.
    Please see README.md
  }
end
