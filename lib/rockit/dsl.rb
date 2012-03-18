require 'fileutils'
module Rockit

  class Dsl
    def initialize(app)
      @app = app
    end

    def verbose_on
      @app.debug(true)
    end

    def verbose_off
      @app.debug(false)
    end

    def command(command, options={})
      @app.command(command, options)
    end

    def if_command_missing(command, &block)
      @app.command(command, {:on_failure => block})
    end

    def service(service_name, options={})
      @app.service(service_name, options)
    end

    def if_service_not_running(service_name, &block)
      @app.service(service_name, {:on_failure => block})
    end

    def if_directory_changed(directory, &block)
      exit unless Dir.exists?(directory)
      @app.if_directory_changed(directory, &block)
    end

    def if_file_changed(filename, &block)
      exit unless File.exists?(filename)
      @app.if_file_changed(filename, &block)
    end

    def if_first_time(&block)
      @app.if_first_time(&block)
    end

    def if_string_changed(changeable, name, &block)
      @app.if_string_changed(name, changeable, &block)
    end

    def if_string_digest_changed(name, changeable, &block)
      @app.if_string_digest_changed(name, changeable, &block)
    end

    def run(command, options={})
      @app.system_exit_on_error(command, options)
    end
  end
end