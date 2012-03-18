require 'digest'
require 'fileutils'

require 'rockit/dsl'
require 'rockit/hash_store'

module Rockit

  class Application

    CONFIG_DEFAULTS = ['rockitfile', 'Rockitfile', 'rockitfile.rb', 'Rockitfile.rb']

    def initialize(store=nil)
      @hash_store = store || HashStore.new
    end

    # Run a Rockit configuration file and Rails dependency checks
    # unless turned off by configuration.
    def run
      rockit_file = CONFIG_DEFAULTS.select { |f| File.exists?(f) }.first
      raise ArgumentError "No Rockitfile found (looking for: #{CONFIG_DEFAULTS.join(',')})" unless rockit_file
      Dsl.new(self).instance_eval(File.read(rockit_file), rockit_file)
    end

    # Remove the cache directory
    def clear_cache
      @hash_store.clear
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

    # If the directly file listing changes, execute the block.
    def if_directory_changed(directory, &block)
      if_string_digest_changed(directory, Dir.glob("#{directory}/*").join(","), &block)
    end

    # First time executed call the block.
    def if_first_time(&block)
      if_string_changed("first_time", "done", &block)
    end

    # If the digest of the input is different from the stored key, execute the block.
    def if_string_digest_changed(key, input, &block)
      if_string_changed(key, Digest::SHA256.new.update(input.to_s).hexdigest.to_s, &block)
    end

    # If the digest of the file is different from the stored digest, execute the block.
    def if_file_changed(file, &block)
      if_string_changed(file, Digest::SHA256.file(file).hexdigest.to_s, &block)
    end

    # Execute the given block if the input is different from
    # the output .
    #
    # key - the key to lookup the stored hash value
    # new_value - the value to compare with the stored hash value
    # block - block to execute if the hash value does not match the stored hash value
    #
    # return if the block was not executed, false, if it is executed, the return
    #         status of the block
    def if_string_changed(key, new_value, &block)
      if new_value != @hash_store[key]
        old_value = @hash_store[key]
        @hash_store[key] = new_value
        block.call(key, new_value, old_value) if block_given?
      end
    end

    # Run system commands and if not successful exit and print out an error
    # message. Default behavior is to print output of a command when it does
    # not return success.
    #
    # command - the system command you want to execute
    # options - 'error_message' - a message to print when command is not successful
    #           'print_command' - displays the command being run
    #           'failure_callback' - Proc to execute when the command fails
    #           'on_success' - Proc to execute when the command is successful
    #
    # returns only true, will perform exit() when not successful
    #
    def system_exit_on_error(command, options={})
      options = {'print_command' => true}.merge(string_keys(options))
      output command if options['print_command']
      command_output = system_command(command)
      unless last_process.success?
        options['on_failure'].call(command, options) if options['on_failure'].is_a?(Proc)
        output options['failure_message'] || command_output
        return exit(last_process.exitstatus)
      end
      options['on_success'].call(command, options) if options['on_success'].is_a?(Proc)
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