module TransportProfiles
  class Steps::DeleteFile < Steps::Step

    def initialize(path, gateway)
      super("Delete file: #{path}", gateway)
      @path = path
    end

    def resolve_files(process_context)
      found_name = @path.kind_of?(Symbol) ? process_context.get(@path) : @path
      found_name.kind_of?(Array) ? found_name : [found_name]
    end

    def execute(process_context)
      delete_paths = resolve_files(process_context)
      delete_paths.each do |del_path|
        File.delete(del_path.path)
      end
    end

  end
end
