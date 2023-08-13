# frozen_string_literal: true

module Eligible
  # Eligibility model
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps

    STATUSES = %i[initial published expired].freeze

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

    scope :by_key, ->(key) { where(key: key.to_sym) }
    scope :effectuated, -> { where(:current_state.ne => :initial) }

    def latest_state_history
      state_histories.max_by(&:created_at)
    end

    def eligibility_period_cover?(date)
      if current_state == :initial
        (effective_on..effective_on.end_of_year).cover?(date)
      else
        return false unless published_on
        (published_on..expired_on).cover?(date)
      end
    end

    def published_on
      publish_history = state_histories.by_state(:published).min_by(&:created_at)
      publish_history&.effective_on
    end

    #default expired_on will be last day of callender year of the eligibility
    #eligibility can't span across multiple years
    #once eligibility is expired, it can never be moved back to published state
    def expired_on
      expiration_history = state_histories.by_state(:expired).min_by(&:created_at)
      expiration_history&.effective_on&.prev_day || published_on&.end_of_year
    end

    def is_eligible_on?(date)
      evidences.all? { |evidence| evidence.is_eligible_on?(date) }
    end

    def grant_for(grant_key)
      grants
        .by_key(grant_key)
        .detect { |grant| grant.value&.item.to_s == "true" }
    end

    class << self
      ResourceReference = Struct.new(:class_name, :optional, :meta)

      RESOURCE_KINDS = [
        BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::AdminAttestedEvidence,
        BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant,
        IvlOsseEligibilities::AdminAttestedEvidence,
        IvlOsseEligibilities::IvlOsseGrant
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
        collection.map do |item|
          model = resource_ref_dir[type][item.key].class_name.sub(/^::/, '')
          item_class = RESOURCE_KINDS.find { |kind| kind.name == model }

          next unless item_class
          item_class.new(item.to_h)
        end.compact
      end
    end
  end
end
