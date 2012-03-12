require 'digest'
require 'fileutils'

require 'rocketstrap/dsl'

module Rocketstrap

  class Application

    CACHE_DIR = '.rocketstrap'

    RAILS_DEPENDENCIES = [
      {:checksum => 'Gemfile', :name => 'gemfile', :command => 'bundle'},
      {:checksum => lambda { '1' }, :name => 'db_create', :command => 'rake db:create'},
      {:checksum => lambda { Dir.glob('db/migrate/*') }, :name => 'db_migrate', :command => 'rake db:migrate'},
    #  {:checksum => 'db/seeds.rb', :name => 'seeds', :command => 'rake db:seed'} # there is not an easy way to rerun db:seeds
    ]

    # Run a Rocketstrap configuration file and Rails dependency checks
    # unless turned off by configuration.
    def run(rocketfile="Rocketfile")
      run_rails_checks = true
      if File.exists?(rocketfile)
        rocket_dsl = Rocketstrap::Dsl.new(self)
        rocket_dsl.instance_eval(File.read(rocketfile), rocketfile)
        run_rails_checks = rocket_dsl.rails_checks_enabled
      end
      rails_checks if run_rails_checks
    end

    # Run default Rails dependency checks. If one of the dependencies fail, it will
    # hard exit printing the output of the failure.
    #
    # return only if it finishes successfully
    def rails_checks
      RAILS_DEPENDENCIES.each do |dependency|
        if_checksum_changed(dependency[:checksum], "#{dependency[:name]}_checksum") do
          system_exit_on_error(dependency[:command])
        end
      end
    end

    # Remove the cache directory
    def clear_cache
      FileUtils.rm_rf(CACHE_DIR)
    end

    # Determine if the command exists on the current system (uses which). If it does
    # not hard exit with a message to stdout.
    #
    # command - the string of the command to find
    # options - see system_exit_on_error
    #
    # return only if it finishes successfully
    def command(command, options)
      options = {
        'print_command' => false,
        'failure_message' => "required command '#{command}' is not available."
      }.merge(string_keys(options))
      system_exit_on_error("which #{command}", options)
    end

    # Identify if a service is running on the system (uses ps). If it does not
    # hard exit with a message to stdout.
    #
    # service_name - the name of the service to find in ps
    # options - see system_exit_on_error
    #
    # return only if it finishes successfully
    def service(service_name, options={})
      options = {
        'print_command' => false,
        'failure_message' => "required service '#{service_name}' is not running."
      }.merge(string_keys(options))
      system_exit_on_error("ps ax | grep '#{service_name.gsub(/^(.)/, "[\\1]")}'", options)
    end

    # TODO : consider caching all checksums in single file...
    #
    # Execute the given block if the input checksum is different from
    # the output checksum.
    #
    # input - a proc or filename
    #         Proc - will be called and the output to_s to determine the hex digest
    #         filename - file will be used to determine the hex digest.
    # output_file - an output filename to store the checksum for subsequent calls. Will
    #         be created first time if it does not exist.
    #
    # return if the block was not executed, false, if it is executed, the return
    #         status of the block
    def if_checksum_changed(input, output_file)
      ret = false
      out_path = File.join(CACHE_DIR, output_file)
      begin
        if input.is_a?(Proc)
          checksum = Digest::SHA256.new.update(input.call.to_s).hexdigest
        else
          checksum = Digest::SHA256.file(input).hexdigest
        end
        current_checksum = File.exists?(out_path) ? File.read(out_path).strip : nil
      ensure
        if checksum != current_checksum
          ret = yield
          Dir.mkdir(CACHE_DIR) unless File.exists?(CACHE_DIR)
          File.open(out_path, 'w+') do |f|
            f.write(checksum)
          end
        end
      end
      ret
    end

    # TODO : think about allowing failure_callback to initiate a retry or to return success
    #
    # Run system commands and if not successful exit and print out an error
    # message. Default behavior is to print output of a command when it does
    # not return success.
    #
    # command - the system command you want to execute
    # options - 'error_message' - a message to print when command is not successful
    #           'print_command' - displays the command being run
    #           'failure_callback' - Proc to execute when the command fails
    #           'success_callback' - Proc to execute when the command is successful
    #
    # returns only true, will perform exit() when not successful
    #
    def system_exit_on_error(command, options={})
      options = {'print_command' => true}.merge(string_keys(options))
      output command if options['print_command']
      command_output = system_command(command)
      unless last_process.success?
        options['failure_callback'].call(command, options) if options['failure_callback'].is_a?(Proc)
        output options['failure_message'] || command_output
        return exit(last_process.exitstatus)
      end
      options['success_callback'].call(command, options) if options['success_callback'].is_a?(Proc)
      true
    end

    # Execute a system command and return the result. Guard against calls
    # to `rm -rf`.
    #
    # command - the system command to execute
    #
    # returns the result of the command execution
    #
    # raises exception on calls to `rm -rf`
    #
    def system_command(command)
      raise "No I'm not going to delete your hd" if command.strip == "rm -rf"
      `#{command}`
    end

    # Pulling from ActiveSupport::CoreExtensions::Hash::Keys to avoid
    # having to include the entire gem.
    #
    # hash - the hash to convert keys to strings
    #
    # returns a new hash with only string keys
    def string_keys(hash={})
      hash.inject({}) do |options, (key, value)|
        options[key.to_s] = value
        options
      end
    end

    private

    # Helper to the last process, mainly for testing.
    def last_process
      $?
    end

    # Helper to a hard exit, mainly for testing.
    def exit(status)
      Kernel.exit(status)
    end

    # Helper to output to stdout.
    def output(s)
      puts s
    end

  end
end