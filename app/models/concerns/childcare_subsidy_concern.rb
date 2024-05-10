# frozen_string_literal: true

# Concern to add osse eligibility support for consumer/resident roles
module ChildcareSubsidyConcern
  extend ActiveSupport::Concern

  included do
    embeds_many :eligibilities,
                class_name: "::Eligible::Eligibility",
                as: :eligible,
                cascade_callbacks: true

    after_create :create_default_osse_eligibility

    def osse_eligible?(start_on)
      return false unless osse_feature_enabled_for?(start_on.year)

      is_osse_eligibility_satisfied?(start_on)
    end

    def has_osse_grant?(key, effective_date)
      eligibility = active_eligibility_on(effective_date)
      return unless eligibility

      eligibility.grant_for(key).present?
    end

    def is_osse_eligibility_satisfied?(start_on)
      active_eligibility_on(start_on)&.present? || false
    end

    def osse_feature_enabled_for?(year)
      ::EnrollRegistry.feature?("aca_ivl_osse_eligibility_#{year}") &&
        ::EnrollRegistry.feature_enabled?("aca_ivl_osse_eligibility_#{year}")
    end

    def eligibilities_on(date)
      eligibility_key = "aca_ivl_osse_eligibility_#{date.year}".to_sym

      eligibilities.by_key(eligibility_key)
    end

    def eligibility_on(effective_date)
      eligibilities_on(effective_date).last
    end

    def active_eligibilities_on(date)
      eligibilities_on(date).select { |e| e.is_eligible_on?(date) }
    end

    def active_eligibility_on(effective_date)
      active_eligibilities_on(effective_date).last
    end

    def create_or_term_eligibility(eligibility_params)
      osse_eligibility = eligibility_params[:evidence_value].to_s

      return if osse_eligibility == "true" && is_osse_eligibility_satisfied?(eligibility_params[:effective_date])
      store_eligibility(eligibility_params)
    end

    def osse_eligibility_params(evidence_value, effective_date = nil)
      effective_date ||= TimeKeeper.date_of_record
      if EnrollRegistry.feature_enabled?(
        "aca_ivl_osse_effective_beginning_of_year"
      )
        effective_date =
          effective_date.beginning_of_year
      end

      {
        subject: self.to_global_id,
        evidence_key: :ivl_osse_evidence,
        evidence_value: evidence_value.to_s,
        effective_date: effective_date
      }
    end

    def store_eligibility(eligibility_params)
      params =
        osse_eligibility_params(
          eligibility_params[:evidence_value],
          eligibility_params[:effective_date]
        )
      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(
        params
      )
    end

    def create_default_osse_eligibility
      return unless osse_feature_enabled_for?(TimeKeeper.date_of_record.year)

      ::BenefitCoveragePeriod.osse_eligibility_years_for_display.each do |year|
        next unless year >= TimeKeeper.date_of_record.year

        begin
          effective_date = Date.new(year, 1, 1)
          next if eligibility_on(effective_date)

          operation = ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new
          operation.default_eligibility = true
          operation.call(
            osse_eligibility_params(false, effective_date)
          )
        rescue StandardError => e
          Rails.logger.error do
            "Default Osse Eligibility not created for #{self.to_global_id} due to #{e.backtrace}"
          end
        end
      end
    end
  end
end
