# frozen_string_literal: true

module Eligibilities
  module Osse
    # Eligibility model
    class Eligibility
      include Mongoid::Document
      include Mongoid::Timestamps
      include GlobalID::Identification

      # DUE_DATE_STATES = %w[review outstanding rejected].freeze

      belongs_to :eligibility, polymorphic: true

      field :title, type: String
      field :description, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :status, type: String
      # field :updated_by, type: String
      # field :update_reason, type: String

      embeds_one :subject, class_name: "::Eligibilities::Osse::Subject", cascade_callbacks: true
      embeds_many :evidences, class_name: "::Eligibilities::Osse::Evidence", cascade_callbacks: true
      embeds_many :grants, class_name: "::Eligibilities::Osse::Grant", cascade_callbacks: true

      accepts_nested_attributes_for :subject, :evidences, :grants

      validates_presence_of :start_on

      after_create :create_grants

      scope :by_date, lambda { |compare_date = TimeKeeper.date_of_record|
        where(
          "$or" => [
            { :start_on.lte => compare_date, :end_on => nil},
            { :start_on.lte => compare_date, :end_on.gte => compare_date }
          ]
        )
      }

      def create_grants
        grant_values = evidences.inject([]) do |values, evidence|
          grant_result = Operations::Eligibilities::Osse::GenerateGrants.new.call(
            {
              eligibility_gid: self.to_global_id,
              evidence_key: evidence.key
            }
          )

          values += grant_result.success if grant_result.success?
          values
        end

        persist_grants(grant_values)
      end

      def persist_grants(grant_values)
        grant_values.each do |grant_value|
          attributes = grant_value.to_h
          grant = self.grants.new
          grant.assign_attributes(attributes.except(:value))
          grant.value = grant_value_klass.constantize.new(attributes[:value].merge(value: attributes[:key]))
          grant.save
        end
      end

      #
      # hard coded inside engine
      #
      def grant_value_klass
        'Eligibilities::Osse::BenefitSponsorshipOssePolicy'
      end

      def grant_for(value)
        grants.detect do |grant|
          value_instance = grant.value
          value_instance.value.to_s == value.to_s
        end
      end
    end
  end
end
