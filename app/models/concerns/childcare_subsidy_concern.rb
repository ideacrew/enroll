# frozen_string_literal: true

# Concern to add osse eligibility support for consumer/resident roles
module ChildcareSubsidyConcern
  extend ActiveSupport::Concern

  included do
    has_many :eligibilities, class_name: "::Eligibilities::Osse::Eligibility", as: :eligibility

    embeds_many :ivl_eligibilities, class_name: '::Eligible::Eligibility', cascade_callbacks: true

    def osse_eligible?(start_on)
      return false unless osse_feature_enabled_for?(start_on.year)

      is_osse_eligibility_satisfied?(start_on)
    end

    def is_osse_eligibility_satisfied?(start_on)
      eligibility = eligibility_for(:ivl_osse_eligibility, start_on)
      return false unless eligibility

      eligibility.is_eligible_on?(start_on)
    end

    def osse_feature_enabled_for?(year)
      ::EnrollRegistry.feature?("aca_ivl_osse_subsidy_#{year}") && ::EnrollRegistry.feature_enabled?("aca_ivl_osse_subsidy_#{year}")
    end

    def eligibility_for(eligibility_key, start_on)
      eligibilities = ivl_eligibilities.by_key(eligibility_key)
      eligibilities.select(&:effectuated?).detect do |eligibility|
        eligibility.eligibility_period_cover?(start_on)
      end
    end

    def create_or_term_eligibility(eligibility_params)
      osse_eligibility = eligibility_params[:evidence_value]
      if is_osse_eligibility_satisfied?(eligibility_params[:effective_date])
        return if osse_eligibility == 'true'
        terminate_eligibility(eligibility_params)
      elsif osse_eligibility == 'true'
        ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(osse_eligibility_params(osse_eligibility))
      end
    end

    def osse_eligibility_params(osse_eligibility)
      effective_date = if EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year")
                         TimeKeeper.date_of_record.beginning_of_year
                       else
                         TimeKeeper.date_of_record
                       end

      {
        subject: self.to_global_id,
        evidence_key: :ivl_osse_evidence,
        evidence_value: osse_eligibility.to_s,
        effective_date: effective_date
      }
    end

    def terminate_eligibility(eligibility_params)
      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call({
                                                                              subject: self.to_global_id,
                                                                              evidence_key: :ivl_osse_evidence,
                                                                              evidence_value: eligibility_params[:evidence_value].to_s,
                                                                              effective_date: eligibility_params[:effective_date]
                                                                            })
    end
  end
end
