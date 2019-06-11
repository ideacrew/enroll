module Mongoid
  module Association
    module Relatable
      def resolve_name(mod, name)
        cls = exc = nil
        parts = name.to_s.split('::')
        if parts.first == ""
          parts.shift
        end
        namespace_hierarchy(mod).each do |ns|
          begin
            parts.each do |part|
              # Simple const_get sometimes pulls names out of weird scopes,
              # perhaps confusing the receiver (ns in this case) with the
              # local scope. Walk the class hierarchy ourselves one node
              # at a time by specifying false as the second argument.
              ns = ns.const_get(part, false)
            end
            cls = ns
            break
          rescue NameError => e
            if exc.nil?
              exc = e
            end
          end
        end
        if cls.nil?
          # Raise the first exception, this is from the most specific namespace
          raise exc
        end
        cls
      end
    end
  end
end
