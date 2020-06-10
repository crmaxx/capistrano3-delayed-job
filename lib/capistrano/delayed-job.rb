# frozen_string_literal: true

require 'capistrano/bundler'
require "capistrano/plugin"

module Capistrano
  module DelayedJobCommon
    def delayed_job_switch_user(role)
      user = delayed_job_user(role)
      if user == role.user
        yield
      else
        backend.as user do
          yield
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

    def template_delayed_job(from, to, role)
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
      backend.upload! StringIO.new(ERB.new(erb, trim_mode: '-').result(binding)), to
    end

    def execute_delayed_job(command)
      backend.execute "cd /home/#{fetch(:user)}/#{fetch(:application)}/current && (export RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} RACK_ENV=#{fetch(:rails_env)}; #{fetch(:rbenv_prefix)} #{fetch(:delayed_job_restart_command)} #{command})"
    end
  end

  class DelayedJob < Capistrano::Plugin
    include DelayedJobCommon

    def define_tasks
      eval_rakefile File.expand_path('tasks/delayed_job.rake', __dir__)
    end

    def set_defaults
      set_if_empty :delayed_job_role, :app
      set_if_empty :delayed_job_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :delayed_job_workers, 1
      set_if_empty :delayed_job_pid, -> { File.join(shared_path, 'tmp', 'pids', 'delayed_job.pid') }
      set_if_empty :delayed_job_log, -> { File.join(shared_path, 'log', 'delayed_job.log') }
      set_if_empty :delayed_job_conf, -> { File.join(shared_path, 'config', 'initializers', 'delayed_job_config.rb') }
      set_if_empty :delayed_job_restart_command, 'bundle exec bin/delayed_job'

      # Chruby, Rbenv and RVM integration
      append :chruby_map_bins, 'delayed_job'
      append :rbenv_map_bins, 'delayed_job'
      append :rvm_map_bins, 'delayed_job'

      # Bundler integration
      append :bundle_bins, 'delayed_job'
    end

    def register_hooks
      after 'deploy:check', 'delayed_job:check'
      after 'deploy:finished', 'delayed_job:restart'
    end

    def delayed_job_workers
      fetch(:delayed_job_workers, 1)
    end

    def upload_delayed_job_config_rb(role)
      template_delayed_job 'delayed_job_config', fetch(:delayed_job_conf), role
    end

    def delayed_job_for(command)
      execute_delayed_job(command)
    end
  end
end

require 'capistrano/delayed-job/jungle'
