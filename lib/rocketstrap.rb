require "digest"
require "fileutils"

module Manilla
  module Bootstrap

    CACHE_DIR = '.bootstrap'

    SERVICES = ['solr','mysql','redis','memcache']
    COMMANDS = ['convert', 'bundle']
    RAILS_DEPENDENCIES = [
        {:checksum => 'Gemfile', :name => 'gemfile', :command => 'bundle'},
        {:checksum => lambda{ '1' }, :name => 'db_create', :command => 'rake db:create'},
        {:checksum => lambda{ Dir.glob('db/migrate/*') }, :name => 'db_migrate', :command => 'rake db:migrate'},
        {:checksum => 'db/seeds.rb', :name => 'seeds', :command => 'rake db:seed'}
    ]

    def run
      services
      commands
      rails_dep
    end

    # SERVICES : mysql, redis, solr, memcache
    def services
      SERVICES.each do |service|
        system_exit_on_error("ps ax | grep '#{service.gsub(/^(.)/,"[\\1]")}'",
          {:print_command => false,
            :error_message => "required service '#{service}' is not running, see engineering wiki for more information."})
      end
    end

    # COMMANDS : imagemagick
    def commands
      COMMANDS.each do |comm|
        system_exit_on_error("which #{comm}",
          {:print_command => false,
            :error_message => "required command '#{comm}' is not available, see engineering wiki for more information."})
      end
    end

    def rails_dep
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

    # Execute the given block if the input checksum is different from
    # the output checksum.
    #
    # input - a proc or filename
    #         Proc - will be called and the output to_s to determine the hex digest
    #         filename - file will be used to determine the hex digest.
    # out_file - an output filename to store the checksum for subsequent calls. Will
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

    # Run system commands and if not successful exit and print out an error
    # message. Default behavior is to print output of a command when it does
    # not return success.
    #
    # command - the system command you want to execute
    # options - [:error_message] - a message to print when command is not successful
    #
    # returns only true, will perform exit() when not successful
    #
    def system_exit_on_error(command, options={})
      options = {:error_message => nil, :print_command => true}.merge(options)
      puts command if options[:print_command]
      output = `#{command}`
      unless $?.success?
        puts options[:error_message] || output
        exit
      end
      true
    end
  end
end

# run the bootstrap
Manilla::Bootstrap.clear_cache if ARGV[0] == '-f'
Manilla::Bootstrap.run