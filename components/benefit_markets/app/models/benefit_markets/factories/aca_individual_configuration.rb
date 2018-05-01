module BenefitMarkets
  module Factories
    class AcaIndividualConfiguration
      def self.call(initial_application_configuration:, mm_enr_due_on:, open_enrl_end_on:, open_enrl_start_on:, vr_due:, vr_os_window:)
        BenefitMarkets::AcaIndividualConfiguration.new initial_application_configuration: initial_application_configuration,
          mm_enr_due_on: mm_enr_due_on,
          open_enrl_end_on: open_enrl_end_on,
          open_enrl_start_on: open_enrl_start_on,
          vr_due: vr_due,
          vr_os_window: vr_os_window
      end

      def self.validate(benefit_market)
        benefit_market.valid?
      end
    end
  end
end