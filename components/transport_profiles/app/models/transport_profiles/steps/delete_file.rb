module TransportProfiles
  class Steps::DeleteFile < Steps::Step

    def initialize(path, gateway)
      super("Delete file: #{path}", gateway)
      @path = path
    end

    def execute
      File.delete(@path.path)
    end

  end
end
