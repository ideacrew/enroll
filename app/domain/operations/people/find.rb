# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class Find
      include Dry::Monads[:do, :result]

      def call(params)
        yield validate(params)
        person = yield fetch_person(params)

        Success(person)
      end

      private

      def validate(params)
        return Success(params) if params[:person_id].present? || params[:person_hbx_id].present?
        Failure("Provide person_id or person_hbx_id to fetch person")
      end

      def fetch_person(params)
        person = if params[:person_id]
                   Person.where(id: params[:person_id]).first
                 elsif params[:person_hbx_id]
                   Person.by_hbx_id(params[:person_hbx_id]).first
                 end

        if person
          Success(person)
        else
          Failure({:message => ['Person not found']})
        end
      end
    end
  end
end
