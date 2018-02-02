module TransportGateway
  class ResourceEntry
    attr_reader :name, :uri, :size, :mtime

    def initialize(name, uri, size, mtime)
      @name = name
      @uri = uri
      @size = size
      @mtime = mtime
    end
  end
end
