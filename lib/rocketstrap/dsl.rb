module Rocketstrap
  class Dsl

    attr_reader :rails_checks_enabled

    def initialize(app)
      @rails_checks_enabled = true
      @app = app
    end

    def command(command, options={})
      @app.command(command, options)
    end

    def service(service_name, options={})
      @app.service(service_name, options)
    end

    def rails_checks_off
      @rails_checks_enabled = false
    end
  end
end