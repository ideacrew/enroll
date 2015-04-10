module MongoidSupport
  module AssociationProxies
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def associated_with_one(attr_name, key_name, kls_name)
        kls = kls_name
        class_eval(<<-RUBYCODE)
          def #{attr_name}
            return nil if self.#{key_name}.blank?
            #{kls}.find(self.#{key_name})
          end

          def #{attr_name}=(val)
            self.#{key_name} = val.id
          end
        RUBYCODE
      end
    end
  end
end
