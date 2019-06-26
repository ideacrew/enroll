# frozen_string_literal: true

module Services
  class ApplicableAptcService

    def initialize(enrollment_id, selected_aptc)
      @enrollment_id = enrollment_id
      @selected_aptc = selected_aptc
    end

    def applicable_aptc
      factory_klass.new(@enrollment_id, @selected_aptc).fetch_applicable_aptc
    end

    private

    def factory_klass
      Factories::EligibilityFactory
    end
  end
end
