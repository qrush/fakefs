module FakeFS
  class File
    PATH_SEPARATOR = '/'

    def self.extname(path)
      RealFile.extname(path)
    end

    def self.join(*parts)
      parts * PATH_SEPARATOR
    end

    def self.exist?(path)
      !!FileSystem.find(path)
    end

    class << self
      alias_method :exists?, :exist?

      # Assuming that everyone can read files
      alias_method :readable?, :exist?
    end

    def self.size(path)
      read(path).length
    end

    def self.size?(path)
      if exists?(path) && !size(path).zero?
        true
      else
        nil
      end
    end

    def self.const_missing(name)
      RealFile.const_get(name)
    end

    def self.directory?(path)
      if path.respond_to? :entry
        path.entry.is_a? FakeDir
      else
        result = FileSystem.find(path)
        result ? result.entry.is_a?(FakeDir) : false
      end
    end

    def self.symlink?(path)
      if path.respond_to? :entry
        path.is_a? FakeSymlink
      else
        FileSystem.find(path).is_a? FakeSymlink
      end
    end

    def self.file?(path)
      if path.respond_to? :entry
        path.entry.is_a? FakeFile
      else
        result = FileSystem.find(path)
        result ? result.entry.is_a?(FakeFile) : false
      end
    end

    def self.expand_path(*args)
      RealFile.expand_path(*args)
    end

    def self.basename(*args)
      RealFile.basename(*args)
    end

    def self.dirname(path)
      RealFile.dirname(path)
    end

    def self.readlink(path)
      symlink = FileSystem.find(path)
      FileSystem.find(symlink.target).to_s
    end

    def self.open(path, mode='r', perm = 0644)
      if block_given?
        yield new(path, mode, perm)
      else
        new(path, mode, perm)
      end
    end

    def self.read(path)
      file = new(path)
      if file.exists?
        file.read
      else
        raise Errno::ENOENT
      end
    end

    def self.readlines(path)
      read(path).split("\n")
    end

    def self.mtime(path)
      if exists?(path)
        FileSystem.find(path).mtime
      else
        raise Errno::ENOENT
      end
    end

    attr_reader :path
    def initialize(path, mode = nil, perm = nil)
      @path = path
      @mode = mode
      @file = FileSystem.find(path)
      @open = true
      @stream = StringIO.new(@file.content) if @file
    end

    def close
      @open = false
    end

    def read(chunk = nil)
      raise IOError.new('closed stream') unless @open
      @stream.read(chunk)
    end

    def rewind
      @stream.rewind
    end

    def exists?
      @file
    end

    def puts(*content)
      content.flatten.each do |obj|
        write(obj.to_s + "\n")
      end
    end

    def write(content)
      raise IOError.new('closed stream') unless @open

      if !File.exists?(@path)
        @file = FileSystem.add(path, FakeFile.new)
      end

      @file.content += content
    end
    alias_method :print, :write
    alias_method :<<, :write

    def flush; self; end
  end
end
