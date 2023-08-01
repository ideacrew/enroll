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
      eligibility = eligibility_for(:osse_subsidy, start_on)
      return false unless eligibility
      evidence = eligibility.evidences.by_key(:osse_subsidy).max_by(&:created_at)
      evidence&.is_satisfied == true
    end

    def osse_feature_enabled_for?(year)
      ::EnrollRegistry.feature?("aca_ivl_osse_subsidy_#{year}") && ::EnrollRegistry.feature_enabled?("aca_ivl_osse_subsidy_#{year}")
    end

    def eligibility_for(evidence_key, start_on)
      eligibilities.by_date(start_on).select do |eligibility|
        eligibility.evidences.by_key(evidence_key).present?
      end.max_by(&:created_at)
    end

    def create_or_term_eligibility(eligibility_params)
      osse_eligibility = eligibility_params[:evidence_value]
      if is_osse_eligibility_satisfied?(eligibility_params[:effective_date])
        return if osse_eligibility == 'true'
        terminate_eligibility(eligibility_params)
      elsif osse_eligibility == 'true'
        ::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(osse_eligibility_params(osse_eligibility))
      end
    end

    def self.osse_eligibility_params(osse_eligibility)
      effective_date = if EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year")
                         TimeKeeper.date_of_record.beginning_of_year
                       else
                         TimeKeeper.date_of_record
                       end

      {
        subject: self.to_global_id,
        evidence_key: :ivl_osse_evidence,
        evidence_value: osse_eligibility.to_s,
        effective_date: effective_date,
        eligibility_key: :ivl_osse_eligibility
      }
    end

    def terminate_eligibility(eligibility_params)
      ::Operations::Eligibilities::Osse::TerminateEligibility.new.call(
        {
          subject_gid: self.to_global_id.to_s,
          evidence_key: :osse_subsidy,
          termination_date: eligibility_params[:effective_date]
        }
      )
    end
  end
end
