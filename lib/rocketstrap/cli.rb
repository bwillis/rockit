require 'rocketstrap/application'

module Rocketstrap
  class Cli

    # Run the cli. Additional commands supplied will be executed after
    # the Rocketstrap::Application finishes successfully.
    #
    # args - will look for -f as the first argument which will cause a
    #       hard delete of the cache directory before running
    #
    def self.start(args=ARGV)
      rocketapp = Rocketstrap::Application.new
      if args[0] == '-f'
        args.shift
        rocketapp.clear_cache
      end
      rocketapp.run
      Kernel.exec(*args)
    end
  end
end