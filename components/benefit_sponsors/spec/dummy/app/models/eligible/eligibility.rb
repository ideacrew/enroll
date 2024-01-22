# frozen_string_literal: true

module Eligible
  # Eligibility model
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps
    include GlobalID::Identification

    STATUSES = %i[initial eligible ineligible].freeze

    embedded_in :eligible, polymorphic: true

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :current_state, type: Symbol, default: :initial

    embeds_many :evidences,
                class_name: "::Eligible::Evidence",
                cascade_callbacks: true
    embeds_many :grants,
                class_name: "::Eligible::Grant",
                cascade_callbacks: true

    embeds_many :state_histories,
                class_name: "::Eligible::StateHistory",
                cascade_callbacks: true,
                as: :status_trackable

    validates_presence_of :title
    validates_uniqueness_of :key

    delegate :effective_on,
             :is_eligible,
             to: :latest_state_history,
             allow_nil: false

    delegate :eligible?,
             :is_eligible_on?,
             :eligible_periods,
             to: :decorated_eligible_record,
             allow_nil: true

    scope :by_key, ->(key) { where(key: key.to_sym) }
    scope :eligible, -> { where(current_state: :eligible) }
    scope :ineligible, -> { where(current_state: :ineligible) }

    def latest_state_history
      state_histories.last
    end

    def active_state
      :eligible
    end

    def inactive_state
      :ineligible
    end

    def decorated_eligible_record
      EligiblePeriodHandler.new(self)
    end

    def grant_for(grant_key)
      grants.detect { |grant| grant.value&.item&.to_s == grant_key.to_s }
    end

    class << self
      ResourceReference = Struct.new(:class_name, :optional, :meta)

      RESOURCE_KINDS = [
        BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::AdminAttestedEvidence,
        BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant,
        Eligible::Evidence,
        Eligible::Grant
      ].freeze

      def resource_ref_dir
        @resource_ref_dir ||= Concurrent::Map.new
      end

      def register(resource_kind, name, options)
        resource_set = resource_kind.to_s.pluralize
        resource_ref_dir[resource_set.to_sym] ||= {}
        resource_ref_dir[resource_set.to_sym][name] = ResourceReference.new(
          options[:class_name],
          options[:optional],
          options[:meta]
        )
      end

      def grant(name, **options)
        register(:grant, name, options)
      end

      def evidence(name, **options)
        register(:evidence, name, options)
      end

      def evidences_resource_for(key)
        resource_ref_dir[:evidences]&.dig(key)&.class_name ||
          "Eligible::Evidence"
      end

      def grants_resource_for(key)
        resource_ref_dir[:grants]&.dig(key)&.class_name || "Eligible::Grant"
      end

      def create_objects(collection, type)
        collection
          .map do |item|
            resource_name = send("#{type}_resource_for", item.key)
            item_class =
              RESOURCE_KINDS.find do |kind|
                kind.name == (resource_name.sub(/^::/, ""))
              end

            next unless item_class
            item_class.new(item.to_h)
          end
          .compact
      end
    end
  end
end
