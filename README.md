# Capistrano::DelayedJob

## Installation

Add this line to your application's Gemfile:

    gem "capistrano3-delayed-job", github: "crmaxx/capistrano3-delayed-job", group: :development


And then execute:

    $ bundle

## Usage
```ruby
    # Capfile

    require 'capistrano/delayed-job'
    install_plugin Capistrano::DelayedJob  # Default DelayedJob tasks
    install_plugin Capistrano::DelayedJob::Jungle # if you need the jungle tasks
```

To make it work with rvm, rbenv and chruby, install the plugin after corresponding library inclusion.
```ruby
    # Capfile

    require 'capistrano/rbenv'
    require 'capistrano/delayed-job'
    install_plugin Capistrano::DelayedJob
```

### Config

To list available tasks use `cap -T`

To upload delayed_job config use:
```ruby
cap production delayed_job:config
```
By default the file located in  `shared/delayed_job.rb`


Ensure that `tmp/pids`,` tmp/sockets` and `log` are shared (via `linked_dirs`):

`This step is mandatory before deploying, otherwise delayed_job won't start`

### Jungle

For Jungle tasks (beta), these options exist:
```ruby
    set :delayed_job_jungle_conf, '/etc/delayed_job.conf'
    set :delayed_job_run_path, '/usr/local/bin/run-delayed-job'
```

### Other configs

Configurable options, shown here with defaults: Please note the configuration options below are not required unless you are trying to override a default setting, for instance if you are deploying on a host on which you do not have sudo or root privileges and you need to restrict the path. These settings go in the deploy.rb file.

```ruby
    set :delayed_job_pid, "#{shared_path}/tmp/pids/delayed_job.pid"
    set :delayed_job_log, "#{shared_path}/log/delayed_job.log"
    set :delayed_job_env, fetch(:rack_env, fetch(:rails_env, 'production'))
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
