# frozen_string_literal: true

module Services
  class CensusMemberUpdateService

    def factory_klass
      ::Factories::CensusMemberUpdateFactory
    end

    def factory_obj(form)
      @factory_obj ||= factory_klass.new(form)
    end

    def is_valid_relationship?(form)
      factory_obj(form).is_a_valid_relationship?
    end
  end
end
