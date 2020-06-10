require 'capistrano/bundler'
require "capistrano/plugin"

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
      backend.upload! StringIO.new(ERB.new(erb, nil, '-').result(binding)), to
    end
  end

  class DelayedJob < Capistrano::Plugin
    include DelayedJobCommon

    def define_tasks
      eval_rakefile File.expand_path('../tasks/delayed-job.rake', __FILE__)
    end

    def set_defaults
      set_if_empty :delayed_job_role, :app
      set_if_empty :delayed_job_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :delayed_job_workers, 0
      set_if_empty :delayed_job_state, -> { File.join(shared_path, 'tmp', 'pids', 'delayed_job.state') }
      set_if_empty :delayed_job_pid, -> { File.join(shared_path, 'tmp', 'pids', 'delayed_job.pid') }
      set_if_empty :delayed_job_log, -> { File.join(shared_path, 'log', 'delayed_job.log') }
      set_if_empty :delayed_job_restart_command, 'bundle exec bin/delayed_job'

      # # Chruby, Rbenv and RVM integration
      # append :chruby_map_bins, 'puma', 'pumactl'
      # append :rbenv_map_bins, 'puma', 'pumactl'
      # append :rvm_map_bins, 'puma', 'pumactl'

      # # Bundler integration
      # append :bundle_bins, 'puma', 'pumactl'
    end

    def register_hooks
      after 'deploy:check', 'delayed_job:check'
      after 'deploy:finished', 'delayed_job:smart_restart'
    end

    def delayed_job_workers
      fetch(:delayed_job_workers, 1)
    end

    def upload_delayed_job_rb(role)
      template_delayed_job 'delayed_job', fetch(:delayed_jobconf), role
    end
  end
end

require 'capistrano/delayed_job/jungle'
