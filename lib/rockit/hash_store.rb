module Rockit

  class HashStore

    DIR = '.rockit'
    FILE = 'hash'

    attr_accessor :dir, :filename

    def initialize(dir=DIR, filename=FILE)
      @dir = dir
      @filename = filename
    end

    def destroy
      p = File.join(@dir,@filename)
      File.delete(p) if File.exists?(p)
      Dir.rmdir(@dir) if File.exists?(@dir)
    end

    def [](key)
      if m = File.read(filepath).match(/^#{key}:(.*)$/)
        m[1]
      end
    end

    def []=(key, value)
      contents = File.read(filepath)
      contents << "#{key}:#{value}\n" unless contents.gsub!(/^#{key}:.*$/, "#{key}:#{value}")
      File.open(filepath, 'w') {|f| f.write(contents) }
    end

    private

    def filepath
      Dir.mkdir(@dir) unless File.exists?(@dir)
      file = File.join(@dir, @filename)
      File.new(file,File::CREAT) unless File.exists?(file)
      file
    end
  end

end