# frozen_string_literal: true

module Orms
  module Mongoid
    # A mixin for Mongoid::Document classes that provides convenience methods that transform Mongoid Document model
    # instances to AcaEntities Domain models. It will automatically discover the appropriate AcaEntities Domain Entities
    # and Contracts that follow the idiomatic naming conventions.
    #
    # Example:
    #
    #   Define a local Mongoid Document model:
    #
    #   class MyNamespace::MyModel
    #     include Mongoid::Document
    #     include Orms::Mongoid::DomainModel
    #
    #     field :name, type: String
    #     field :age, type: Integer
    #     field :email, type: String
    #   end
    #
    #   Define the corresponding AcaEntities Domain Entity and Contract classes:
    #
    #   class AcaEntities::MyNamespace::MyModel
    #     include Dry::Struct
    #
    #     attribute :name, Types::String
    #     attribute :age, Types::Integer
    #     attribute :email, Types::String
    #   end
    #
    #   class AcaEntities::MyNamespace::Contracts::MyModelContract < Dry::Validation::Contract
    #     params do
    #       optional(:id).value(:string)
    #       required(:name).filled(:string)
    #       required(:age).filled(:integer)
    #       required(:email).filled(:string)
    #     end
    #   end
    #
    #  my_doc = MyNamespace::MyModel.create(name: 'John Doe', age: 30, email: 'john@example.com')
    #  => #<MyNamespace::MyModel: _id: BSON::ObjectId('660bfa34d6264aea6071a3cc'), age: 30,
    #  created_at: Tue, 02 Apr 2024 12:29:40.396660000 UTC +00:00, email: 'john@example.com', name: 'John Doe',
    #  updated_at: Tue, 02 Apr 2024 12:29:40.396660000 UTC +00:00>
    #
    #  my_doc.to_hash
    #  =>
    #  {:age=>30,
    #   :created_at=>Tue, 02 Apr 2024 12:29:40.396660000 UTC +00:00,
    #   :email=>'john@example.com',
    #   :name=>'John Doe',
    #   :updated_at=>Tue, 02 Apr 2024 12:29:40.396660000 UTC +00:00}
    #
    module DomainModel
      extend ActiveSupport::Concern

      included do
        # Returns the Mongoid Document instance fields as a hash with symbolized keys. It also transforms the
        # Mongoid _id key to an id: key with a String type value.
        # Why attributes and not serializable_hash?
        # TODO: Fetch attributes of the associations like has_one, has_many other than embedded_in
        def to_hash
          attributes.deep_symbolize_keys.merge(id: _id.to_s).except(:_id)
        end

=begin
        # Returns an AcaEntities Entity {::Dry::Struct} class instance loaded with this Mongoid model's instance
        # attributes
        def to_entity
          entity_klass.new(to_hash)
        end

        # Saves the Mongoid model instance to the MongoDB data store and returns the instance
        def persist
          save
        end

        # Returns the Mongoid Document instance fields as a hash with symbolized keys. It also transforms the
        # Mongoid _id key to an id: key with a String type value.
        def to_hash
          serializable_hash.deep_symbolize_keys.merge(id: _id.to_s).except(:_id)
        end

        # Returns the AcaEntities Entity class constant for the Mongoid model in which this concern is included
        def entity_klass
          Object.const_get(entity_klass_name)
        end

        # Returns the AcaEntities contract class constant for this given Mongoid model
        def contract_klass
          Object.const_get(contract_klass_name)
        end

        private

        # Construct the idiomatic AcaEntities Entity class name for this Mongoid model class
        def entity_klass_name
          ['AcaEntities', self.class.name].join('::')
        end

        # Construct the idiomatic AcaEntities contract class name for this Mongoid model class
        def contract_klass_name
          ['AcaEntities', namespace, 'Contracts', "#{klass_name}Contract"].join('::')
        end

        def namespace
          self.class.name.deconstantize
        end

        def klass_name
          self.class.name.demodulize
        end
=end
      end
    end
  end
end
