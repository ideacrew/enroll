# frozen_string_literal: true

module Eligible
  # Eligibility model
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps

    STATUSES = %i[initial published expired].freeze

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :current_state, type: Symbol

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

    delegate :effective_on,
             :is_eligible,
             to: :latest_state_history,
             allow_nil: false

    scope :by_key, ->(key) { where(key: key.to_sym) }
    scope :by_date, ->(key) { where(key: key.to_sym) }

    def latest_state_history
      state_histories.max_by(&:created_at)
    end

    def current_state
      latest_state_history&.to_state
    end

    def effectuated?
      current_state != :initial
    end

    def eligibility_period_cover?(date)
      return false unless published_on

      (published_on..expired_on).cover?(date)
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

    def grant_for(value)
      grants.detect do |grant|
        value_instance = grant.value
        value_instance.item.to_s == value.to_s
      end
    end

    class << self
      ResourceReference = Struct.new(:class_name, :optional, :meta)

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

      def create_objects(collection, type)
        collection.map do |item|
          item_class = resource_ref_dir[type][item.key].class_name.constantize
          item_class.new(item.to_h)
        end
      end
    end
  end
end
