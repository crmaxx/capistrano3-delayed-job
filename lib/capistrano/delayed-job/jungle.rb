module Capistrano
  class DelayedJob::Jungle < Capistrano::Plugin
    include DelayedJobCommon

    def set_defaults
      set_if_empty :delayed_job_jungle_conf, '/etc/delayed_job.conf'
      set_if_empty :delayed_job_run_path, '/usr/local/bin/run-delayed-job'
    end

    def define_tasks
      eval_rakefile File.expand_path('../../tasks/jungle.rake', __FILE__)
    end

    def debian_install(role)
      template_delayed_job 'delayed-job-deb', "#{fetch(:tmp_dir)}/delayed_job", role
    end

    def rhel_install(role)
      template_delayed_job 'delayed-job-rpm', "#{fetch(:tmp_dir)}/delayed_job", role
    end
  end
end
