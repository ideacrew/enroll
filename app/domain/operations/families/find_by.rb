# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Operation finds family using primary person hbx_id and generats a Family CV
    class FindBy
      include Dry::Monads[:do, :result]

      # @param [Hash] opts The options to generate family_cv for a given primary person Hbx ID
      # @option opts [String] :person_hbx_id
      # @option opts [Integer] :year
      # @example
      #   { person_hbx_id: '10239', year: 2022 }
      # @return [Dry::Monads::Result]
      def call(params)
        person     = yield find_person(params[:response][:person_hbx_id])
        family     = yield find_primary_family(person)
        cv3_family = yield transform_family(family)
        payload    = yield generate_payload(cv3_family)

        Success(payload)
      end

      private

      def find_person(person_hbx_id)
        person = Person.where(hbx_id: person_hbx_id).first
        if person
          Success(person)
        else
          Failure("Unable to find person with hbx_id: #{person_hbx_id}")
        end
      end

      def find_primary_family(person)
        primary_family = person.primary_family
        if primary_family
          Success(primary_family)
        else
          Failure("No primary family exists for person with hbx_id: #{person.hbx_id}")
        end
      end

      def transform_family(family)
        Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
      end

      def generate_payload(cv3_family)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(cv3_family)

        if result.success?
          Success(result.to_h)
        else
          Failure(result.errors.to_h)
        end
      end
    end
  end
end
