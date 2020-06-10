# frozen_string_literal: true

git_plugin = self

namespace :delayed_job do
  desc 'Setup delayed_job config file'
  task :config do
    on roles(fetch(:delayed_job_role)) do |role|
      git_plugin.upload_delayed_job_config_rb(role)
    end
  end

  desc 'Start delayed_job'
  task :start do
    on roles(fetch(:delayed_job_role)) do |role|
      git_plugin.delayed_job_switch_user(role) do
        if test "[ -f #{fetch(:delayed_job_conf)} ]"
          info "using conf file #{fetch(:delayed_job_conf)}"
        else
          invoke 'delayed_job:config'
        end

        if test("[ -f #{fetch(:delayed_job_pid)} ]") && test(:kill, "-0 $( cat #{fetch(:delayed_job_pid)} )")
          info 'delayed_job is already running'
        else
          within current_path do
            with rack_env: fetch(:delayed_job_env) do
              git_plugin.delayed_job_for("start")
            end
          end
        end
      end
    end
  end

  %w[halt stop status].map do |command|
    desc "#{command} delayed_job"
    task command do
      on roles(fetch(:delayed_job_role)) do |role|
        within current_path do
          git_plugin.delayed_job_switch_user(role) do
            with rack_env: fetch(:delayed_job_env) do
              if test "[ -f #{fetch(:delayed_job_pid)} ]"
                if test :kill, "-0 $( cat #{fetch(:delayed_job_pid)} )"
                  git_plugin.delayed_job_for(command)
                else
                  # delete invalid pid file , process is not running.
                  execute :rm, fetch(:delayed_job_pid)
                end
              else
                # pid file not found, so delayed_job is probably not running or it using another pidfile
                warn 'delayed_job not running'
              end
            end
          end
        end
      end
    end
  end

  %w[phased-restart restart].map do |command|
    desc "#{command} delayed_job"
    task command do
      on roles(fetch(:delayed_job_role)) do |role|
        within current_path do
          git_plugin.delayed_job_switch_user(role) do
            with rack_env: fetch(:delayed_job_env) do
              if test("[ -f #{fetch(:delayed_job_pid)} ]") && test(:kill, "-0 $( cat #{fetch(:delayed_job_pid)} )")
                # NOTE pid exist but state file is nonsense, so ignore that case
                git_plugin.delayed_job_for(command)
              else
                # delayed_job is not running or state file is not present : Run it
                invoke 'delayed_job:start'
              end
            end
          end
        end
      end
    end
  end

  task :check do
    on roles(fetch(:delayed_job_role)) do |role|
      # Create delayed_job_config.rb for new deployments
      unless test "[ -f #{fetch(:delayed_job_conf)} ]"
        warn 'delayed_job_config.rb NOT FOUND!'
        git_plugin.upload_delayed_job_config_rb(role)
        info 'delayed_job_config.rb generated'
      end
    end
  end
end
