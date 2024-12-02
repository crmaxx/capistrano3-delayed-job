# frozen_string_literal: true

git_plugin = self

namespace :delayed_job do
  desc 'Install DelayedJob systemd service'
  task :install do
    on roles(fetch(:delayed_job_role)) do |role|
      upload_compiled_template = lambda do |template_name, unit_filename|
        git_plugin.template_delayed_job template_name, "#{fetch(:tmp_dir)}/#{unit_filename}", role
        systemd_path = fetch(:delayed_job_systemd_conf_dir, git_plugin.fetch_systemd_unit_path)
        if fetch(:delayed_job_systemctl_user) == :system
          sudo "mv #{fetch(:tmp_dir)}/#{unit_filename} #{systemd_path}"
        else
          execute :mkdir, "-p", systemd_path
          execute :mv, "#{fetch(:tmp_dir)}/#{unit_filename}", "#{systemd_path}"
        end
      end

      upload_compiled_template.call("delayed_job.service", "#{fetch(:delayed_job_service_unit_name)}.service")

      # Reload systemd
      git_plugin.execute_systemd("daemon-reload")
      invoke "delayed_job:enable"
    end
  end

  desc 'Uninstall DelayedJob systemd service'
  task :uninstall do
    invoke 'delayed_job:disable'
    on roles(fetch(:delayed_job_role)) do |role|
      systemd_path = fetch(:delayed_job_systemd_conf_dir, git_plugin.fetch_systemd_unit_path)
      if fetch(:delayed_job_systemctl_user) == :system
        sudo "rm -f #{systemd_path}/#{fetch(:delayed_job_service_unit_name)}*"
      else
        execute :rm, "-f", "#{systemd_path}/#{fetch(:delayed_job_service_unit_name)}*"
      end
      git_plugin.execute_systemd("daemon-reload")
    end

  end

  desc 'Enable DelayedJob systemd service'
  task :enable do
    on roles(fetch(:delayed_job_role)) do
      git_plugin.execute_systemd("enable", fetch(:delayed_job_service_unit_name))

      if fetch(:delayed_job_systemctl_user) != :system && fetch(:delayed_job_enable_lingering)
        sudo "loginctl enable-linger #{fetch(:delayed_job_lingering_user)}"
      end
    end
  end

  desc 'Disable DelayedJob systemd service'
  task :disable do
    on roles(fetch(:delayed_job_role)) do
      git_plugin.execute_systemd("disable", fetch(:delayed_job_service_unit_name))
    end
  end

  desc 'Start DelayedJob service via systemd'
  task :start do
    on roles(fetch(:delayed_job_role)) do
      git_plugin.execute_systemd("start", fetch(:delayed_job_service_unit_name))
    end
  end

  desc 'Stop DelayedJob service via systemd'
  task :stop do
    on roles(fetch(:delayed_job_role)) do
      git_plugin.execute_systemd("stop", fetch(:delayed_job_service_unit_name))
    end
  end

  desc 'Restarts or reloads DelayedJob service via systemd'
  task :smart_restart do
    if fetch(:delayed_job_phased_restart)
      invoke 'delayed_job:reload'
    else
      invoke 'delayed_job:restart'
    end
  end

  desc 'Restart DelayedJob service via systemd'
  task :restart do
    on roles(fetch(:delayed_job_role)) do
      git_plugin.execute_systemd("restart", fetch(:delayed_job_service_unit_name))
    end
  end

  desc 'Reload DelayedJob service via systemd'
  task :reload do
    on roles(fetch(:delayed_job_role)) do
      service_ok = if fetch(:delayed_job_systemctl_user) == :system
                     execute("#{fetch(:delayed_job_systemctl_bin)} status #{fetch(:delayed_job_service_unit_name)} > /dev/null", raise_on_non_zero_exit: false)
                   else
                     execute("#{fetch(:delayed_job_systemctl_bin)} --user status #{fetch(:delayed_job_service_unit_name)} > /dev/null", raise_on_non_zero_exit: false)
                   end
      cmd = 'reload'
      unless service_ok
        cmd = 'restart'
      end
      if fetch(:delayed_job_systemctl_user) == :system
        sudo "#{fetch(:delayed_job_systemctl_bin)} #{cmd} #{fetch(:delayed_job_service_unit_name)}"
      else
        execute "#{fetch(:delayed_job_systemctl_bin)}", "--user", cmd, fetch(:delayed_job_service_unit_name)
      end
    end
  end

  desc 'Get DelayedJob service status via systemd'
  task :status do
    on roles(fetch(:delayed_job_role)) do
      git_plugin.execute_systemd("status", fetch(:delayed_job_service_unit_name))
    end
  end
end
