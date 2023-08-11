# frozen_string_literal: true

# Concern to add osse eligibility support for consumer/resident roles
module ChildcareSubsidyConcern
  extend ActiveSupport::Concern

  included do

    embeds_many :eligibilities, class_name: '::Eligible::Eligibility', cascade_callbacks: true

    after_create :create_default_osse_eligibility

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
      ::EnrollRegistry.feature?("aca_ivl_osse_eligibility_#{year}") && ::EnrollRegistry.feature_enabled?("aca_ivl_osse_eligibility_#{year}")
    end

    # we cannot have multiple eligibilities with same key in a given calender year
    def find_eligibility_by(eligibility_key, start_on)
      eligibilities = self.eligibilities&.by_key(eligibility_key)
      eligibilities.detect do |eligibility|
        eligibility.eligibility_period_cover?(start_on)
      end
    end

    def eligibility_for(eligibility_key, start_on)
      eligibilities = self.eligibilities&.by_key(eligibility_key)
      eligibilities.effectuated.detect do |eligibility|
        eligibility.eligibility_period_cover?(start_on)
      end
    end

    def create_or_term_eligibility(eligibility_params)
      osse_eligibility = eligibility_params[:evidence_value].to_s
      if is_osse_eligibility_satisfied?(eligibility_params[:effective_date])
        return if osse_eligibility == 'true'
        terminate_eligibility(eligibility_params)
      elsif osse_eligibility == 'true'
        ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(osse_eligibility_params(eligibility_params))
      end
    end

    def osse_eligibility_params(eligibility_params)
      effective_date = eligibility_params[:effective_date] || TimeKeeper.date_of_record
      effective_date = effective_date.beginning_of_year if EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year")

      {
        subject: self.to_global_id,
        evidence_key: :ivl_osse_evidence,
        evidence_value: eligibility_params[:evidence_value].to_s,
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

    def initial_osse_eligibility_params
      {
        subject: self.to_global_id,
        evidence_key: :ivl_osse_evidence,
        evidence_value: 'false',
        effective_date: TimeKeeper.date_of_record.beginning_of_year
      }
    end

    def create_default_osse_eligibility
      return unless osse_feature_enabled_for?(TimeKeeper.date_of_record.year)
      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(initial_osse_eligibility_params)
    rescue StandardError => e
      Rails.logger.error { "Default Osse Eligibility not created for #{self.to_global_id} due to #{e.backtrace}" }
    end
  end
end
