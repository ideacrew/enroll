# frozen_string_literal: true

# Concern to add osse eligibility support for consumer/resident roles
module ChildcareSubsidyConcern
  extend ActiveSupport::Concern

  included do
    has_many :eligibilities, class_name: "::Eligibilities::Osse::Eligibility",
                             as: :eligibility

    def osse_eligible?(start_on)
      eligibility = eligibility_for(:osse_subsidy, start_on)
      return false unless eligibility
      evidence = eligibility.evidences.by_key(:osse_subsidy).max_by(&:created_at)
      evidence&.is_satisfied == true
    end

    def eligibility_for(evidence_key, start_on)
      eligibilities.by_date(start_on).select do |eligibility|
        eligibility.evidences.by_key(evidence_key).present?
      end.max_by(&:created_at)
    end

    def create_or_term_eligibility(eligibility_params)
      if osse_eligible?(eligibility_params[:effective_date])
        return if eligibility_params[:evidence_value] == 'true'
        terminate_eligibility(eligibility_params)
      elsif eligibility_params[:evidence_value] == 'true'
        eligibility_result = build_eligibility(eligibility_params)
        save_eligibility(eligibility_result) if eligibility_result.success?
        eligibility_result
      end
    end

    def save_eligibility(eligibility_result)
      eligibility = self.eligibilities.build(eligibility_result.success.to_h)
      eligibility.save!
    end

    def build_eligibility(eligibility_params)
      ::Operations::Eligibilities::Osse::BuildEligibility.new.call(
        eligibility_params.merge(subject_gid: self.to_global_id)
      )
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
