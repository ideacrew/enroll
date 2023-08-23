# frozen_string_literal: true

# Concern to add osse eligibility support for consumer/resident roles
module ChildcareSubsidyConcern
  extend ActiveSupport::Concern

  included do

    embeds_many :eligibilities, class_name: '::Eligible::Eligibility', as: :eligible, cascade_callbacks: true

    after_create :create_default_osse_eligibility

    def osse_eligible?(start_on)
      return false unless osse_feature_enabled_for?(start_on.year)

      is_osse_eligibility_satisfied?(start_on)
    end

    def has_osse_grant?(key, effective_date)
      eligibility = eligibility_for("aca_ivl_osse_eligibility_#{effective_date.year}".to_sym, effective_date)
      return false unless eligibility&.is_eligible_on?(effective_date)

      eligibility.grant_for(key).present?
    end

    def is_osse_eligibility_satisfied?(start_on)
      eligibility = eligibility_for("aca_ivl_osse_eligibility_#{start_on.year}".to_sym, start_on)
      return false unless eligibility

      eligibility.is_eligible_on?(start_on)
    end

    def osse_feature_enabled_for?(year)
      ::EnrollRegistry.feature?("aca_ivl_osse_eligibility_#{year}") && ::EnrollRegistry.feature_enabled?("aca_ivl_osse_eligibility_#{year}")
    end

    # we cannot have multiple eligibilities with same key in a given calender year
    def find_eligibility_by(eligibility_key, start_on = nil)
      eligibilities = self.eligibilities&.by_key(eligibility_key)
      return eligibilities.last unless start_on
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
      return if is_osse_eligibility_satisfied?(eligibility_params[:effective_date]) && osse_eligibility == 'true'
      store_eligibility(eligibility_params)
    end

    def osse_eligibility_params(evidence_value, effective_date = nil)
      effective_date ||= TimeKeeper.date_of_record
      effective_date = effective_date.beginning_of_year if EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year")

      {
        subject: self.to_global_id,
        evidence_key: :ivl_osse_evidence,
        evidence_value: evidence_value.to_s,
        effective_date: effective_date
      }
    end

    def store_eligibility(eligibility_params)
      params = osse_eligibility_params(
        eligibility_params[:evidence_value],
        eligibility_params[:effective_date]
      )
      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(params)
    end

    def create_default_osse_eligibility
      return unless osse_feature_enabled_for?(TimeKeeper.date_of_record.year)

      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(osse_eligibility_params(false))
    rescue StandardError => e
      Rails.logger.error { "Default Osse Eligibility not created for #{self.to_global_id} due to #{e.backtrace}" }
    end
  end
end
