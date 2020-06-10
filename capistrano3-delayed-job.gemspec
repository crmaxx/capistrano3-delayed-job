# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/delayed-job/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano3-delayed-job'
  spec.version = Capistrano::DELAYED_JOB_VERSION
  spec.authors = ['Maxim Zhukov']
  spec.email = ['crmaxx@gmail.com']
  spec.description = 'DelayedJob integration for Capistrano 3'
  spec.summary = 'DelayedJob integration for Capistrano'
  spec.homepage = 'https://github.com/crmaxx/capistrano3-delayed-job'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.6.5'

  spec.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.7'
  spec.add_dependency 'capistrano-bundler'
  spec.add_dependency 'delayed_job', '~> 4.1'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'solargraph'
  spec.post_install_message = '
    All plugins need to be explicitly installed with install_plugin.
    Please see README.md
  '
end
