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

    embeds_many :evidences,  class_name: '::Eligible::Evidence', cascade_callbacks: true
    embeds_many :grants, class_name: '::Eligible::Grant', cascade_callbacks: true

    embeds_many :state_histories,
                class_name: '::Eligible::StateHistory',
                cascade_callbacks: true,
                as: :status_trackable

    validates_presence_of :title

    delegate :effective_on,
             :is_eligible,
             to: :latest_state_history,
             allow_nil: false

    def latest_state_history
      state_histories.latest_history
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

# Input params 
# We build params for eligibility/evidence/grant in the enroll 
# we call aca entities to validate and create entity 
# we persist result into our db 

# Operations: 
#    create_eligibility 

#       - build params for eligibiliy
#       - build params for evidence 
#       - build params for grant 

#       - call aca_entities to validate and create entity
#       - persist record into our database 

#    build_eligibility 
#    build_evidence
#    build_grant
#    build_state_history 

#    update_eligibility
#        - subject: GlobalID
#        - fetch persisted eligibility record 
#         - update evidence with new state history (use build state history)
#         - update eligibility based evidence is satisfied or not 
#             - creates new state history under eligibily (use build state history)
#         - call aca_entities to validate and create entity
#         - persist record into our database
#         - subject.eligibilites.find(eligibility[:id]).update # 
#         - subject.save

# We removed state machine from enroll 
#    instead we do state gaurds in aca entities 


# We create default osse eligibility for all sponsors/consumers
   # default eligibility will be in initial state
   # default evidence will be in initial state
   # default grants...we create them 

#  when admin grants osse eligibility from UI
  #  create new state history under evidence with status approved
  #  update eligibility state to published and create a state history record 
  #  do we create grants??? I don't know...depends on grants that existing are relavent or not

