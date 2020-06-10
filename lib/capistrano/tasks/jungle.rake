# frozen_string_literal: true

git_plugin = self

namespace :delayed_job do
  namespace :jungle do
    desc 'Install DelayedJob jungle'
    task :install do
      on roles(fetch(:delayed_job_role)) do |role|
        git_plugin.template_delayed_job 'run-delayed-job', "#{fetch(:tmp_dir)}/run-delayed-job", role
        execute "chmod +x #{fetch(:tmp_dir)}/run-delayed-job"
        sudo "mv #{fetch(:tmp_dir)}/run-delayed-job #{fetch(:delayed_job_run_path)}"
        if test '[ -f /etc/redhat-release ]'
          # RHEL flavor OS
          git_plugin.rhel_install(role)
          execute "chmod +x #{fetch(:tmp_dir)}/delayed_job"
          sudo "mv #{fetch(:tmp_dir)}/delayed_job /etc/init.d/delayed_job"
          sudo 'chkconfig --add delayed_job'
        elsif test '[ -f /etc/lsb-release ]'
          # Debian flavor OS
          git_plugin.debian_install(role)
          execute "chmod +x #{fetch(:tmp_dir)}/delayed_job"
          sudo "mv #{fetch(:tmp_dir)}/delayed_job /etc/init.d/delayed_job"
          sudo 'update-rc.d -f delayed_job defaults'
        else
          # Some other OS
          error 'This task is not supported for your OS'
        end
        sudo "touch #{fetch(:delayed_job_jungle_conf)}"
      end
    end

    desc 'Setup DelayedJob config and install jungle script'
    task :setup do
      invoke 'delayed_job:config'
      invoke 'delayed_job:jungle:install'
      invoke 'delayed_job:jungle:add'
    end

    desc 'Add current project to the jungle'
    task :add do
      on roles(fetch(:delayed_job_role)) do |role|
        sudo "/etc/init.d/delayed_job add '#{current_path}' #{fetch(:delayed_job_user, role.user)} '#{fetch(:delayed_job_conf)}'"
      rescue StandardError => e
        warn e
      end
    end

    desc 'Remove current project from the jungle'
    task :remove do
      on roles(fetch(:delayed_job_role)) do
        sudo "/etc/init.d/delayed_job remove '#{current_path}'"
      end
    end

    %w[start stop restart status].each do |command|
      desc "#{command} delayed_job"
      task command do
        on roles(fetch(:delayed_job_role)) do
          sudo "service delayed_job #{command} #{current_path}"
        end
      end
    end
  end
end
