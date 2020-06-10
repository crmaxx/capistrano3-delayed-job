# frozen_string_literal: true

module Capistrano
  module DelayedJob
    module Generators
      class ConfigGenerator < Rails::Generators::Base
        desc "Create local delayed_job configuration files for customization"
        source_root File.expand_path('templates', __dir__)
        argument :templates_path, type: :string,
                                  default: "config/deploy/templates",
                                  banner: "path to templates"

        def copy_template
          copy_file "../../../../capistrano/templates/delayed_job_config.rb.erb", "#{templates_path}/delayed_job_config.rb.erb"
        end
      end
    end
  end
end
