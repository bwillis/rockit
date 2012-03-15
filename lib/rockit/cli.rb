require 'rockit/application'

module Rockit
  class Cli

    # Run the cli. Additional commands supplied will be executed after
    # the Rockit::Application finishes successfully.
    #
    # args - will look for -f as the first argument which will cause a
    #       hard delete of the cache directory before running
    #
    def self.start(args=ARGV)
      rockitapp = Rockit::Application.new
      if args[0] == '-f'
        args.shift
        rockitapp.clear_cache
      end
      rockitapp.run
      Kernel.exec(*args) unless args.size == 0
    end
  end
end