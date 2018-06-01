module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployeePolicySet < ::Importers::Mhc::ConversionEmployeePolicySet

      def create_model(record_attrs)
        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
        case the_action
        when "delete"
          ::Importers::ConversionEmployeePolicyDelete.new(record_attrs.merge({:default_policy_start => @default_policy_start, :plan_year => @plan_year}))
        else
          BenefitSponsors::Importers::ConversionEmployeePolicyAction.new(record_attrs.merge({:default_policy_start => @default_policy_start, :plan_year => @plan_year}))
        end
      end
    end
  end
end
