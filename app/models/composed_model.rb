module ComposedModel

  def self.included(base)
    base.class_eval do
      extend ComposedModel::ComposedModelClassMethods
    end
  end

  module ComposedModelClassMethods
    def composed_of_many(name, klass_name)
      class_eval(<<-RUBYCODE)
        def #{name}=(vals)
          @#{name} ||= []
          if !vals.nil?
             @#{name} = vals
          end
          @#{name}
        end

        def #{name}
          @#{name} ||= []
        end

        def #{name}_attributes
          #{name}.map(&:attributes)
        end

        def #{name}_attributes=(vals)
          if vals.nil?
            @#{name} = []
            return []
          end
          @#{name} = vals.map { |v_attrs| #{klass_name}.new(v_attrs) }
          #{name}_attributes
        end
      RUBYCODE
    end
  end

end
