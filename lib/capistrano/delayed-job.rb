# frozen_string_literal: true

require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  module DelayedJobCommon
    def delayed_job_switch_user(role, &block)
      user = delayed_job_user(role)
      if user == role.user
        block.call
      else
        backend.as user do
          block.call
        end
      end
    end

    def delayed_job_user(role)
      properties = role.properties
      properties.fetch(:delayed_job_user) || # local property for delayed_job only
          fetch(:delayed_job_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
    end

    def compiled_template_delayed_job(from, role)
      @role = role
      file = [
          "lib/capistrano/templates/#{from}-#{role.hostname}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}-#{role.hostname}.rb",
          "lib/capistrano/templates/#{from}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}.rb.erb",
          "lib/capistrano/templates/#{from}.rb",
          "lib/capistrano/templates/#{from}.erb",
          "config/deploy/templates/#{from}.rb.erb",
          "config/deploy/templates/#{from}.rb",
          "config/deploy/templates/#{from}.erb",
          File.expand_path("../templates/#{from}.erb", __FILE__),
          File.expand_path("../templates/#{from}.rb.erb", __FILE__)
      ].detect { |path| File.file?(path) }
      erb = File.read(file)
      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.6')
        StringIO.new(ERB.new(erb, nil, '-').result(binding))
      else
        StringIO.new(ERB.new(erb, trim_mode: '-').result(binding))
      end
    end

    def template_delayed_job(from, to, role)
      backend.upload! compiled_template_delayed_job(from, role), to
    end
  end

  class Puma < Capistrano::Plugin
    include PumaCommon

    def set_defaults
      set_if_empty :delayed_job_role, :app
      set_if_empty :delayed_job_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :delayed_job_workers, 1
      set_if_empty :delayed_job_pid, -> { File.join(shared_path, 'tmp', 'pids', 'delayed_job.pid') }
      set_if_empty :delayed_job_log, -> { File.join(shared_path, 'log', 'delayed_job.log') }
      set_if_empty :delayed_job_conf, -> { File.join(shared_path, 'config', 'initializers', 'delayed_job_config.rb') }
      set_if_empty :delayed_job_restart_command, 'bundle exec bin/delayed_job'

      # Chruby, Rbenv and RVM integration
      append :chruby_map_bins, 'delayed_job' if fetch(:chruby_map_bins)
      append :rbenv_map_bins, 'delayed_job' if fetch(:rbenv_map_bins)
      append :rvm_map_bins, 'delayed_job' if fetch(:rvm_map_bins)

      # Bundler integration
      append :bundle_bins, 'delayed_job'
    end
  end
end

require 'capistrano/delayed_job/systemd'
