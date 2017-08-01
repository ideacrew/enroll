module TransportGateway
  class Adapters::FileAdapter
    include ::TransportGateway::Adapters::Base
    
    def receive_message(message)
      raise ArgumentError.new "source file not provided" if message.from.blank?
      Sources::FileSource.new(message.from.path)
    end

    def send_message(message)
      raise ArgumentError.new "destination not provided" if message.to.blank?
      # Allow empty string sources
      raise ArgumentError.new "source file not provided" if (message.from.blank? && (message.body == nil))
      to_path = message.to.path

      ensure_directory_for(to_path)
      source = provide_source_for(message)
      begin
      File.open(to_path, 'wb') do |f|
        in_stream = source.stream
        while data = in_stream.read(4096) do
          f.write(data)
        end
      end
      ensure
        source.cleanup
      end
    end

    protected

    def provide_source_for(message)
      unless message.body.blank?
        return Sources::StringIOSource.new(message.body)
      end
      gateway.receive_message(message)
    end


    def ensure_directory_for(path)
      dir = File.dirname(path)
      return nil if File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end

  end
end
