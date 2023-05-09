# frozen_string_literal: true

module Operations
  module People
    module Addresses
      # Class to compare address changes and build payload
      class Compare
        include Dry::Monads[:result, :do]

        # params: {person_hbx_id: , address_id: }
        def call(params)
          address_id, person_hbx_id = yield validate(params)
          person = yield find_person(person_hbx_id)
          address = yield find_address(address_id, person)
          change_set = yield build_change_set(address)
          payload = yield build_payload(change_set, person)

          Success(payload)
        end

        private

        def validate(params)
          return Failure("Missing address id ") unless params["address_id"].present?
          return Failure("Missing person hbx id ") unless params["person_hbx_id"].present?
          Success([params["address_id"], params["person_hbx_id"]])
        end

        def find_person(person_hbx_id)
          Operations::People::Find.new.call({person_hbx_id: person_hbx_id})
        end

        def find_address(address_id, person)
          address = person.addresses.where(id: address_id).first
          return Success(address) if address
          Failure("No address found for the given id")
        end

        def build_change_set(address)
          change_set = {}
          history_track = address.history_tracks.last
          Failure("change set payload is only applicable for action :update") unless history_track.action.to_sym == :update
          Failure("No address changes present") unless history_track.original.present? && history_track.modified.present?

          change_set.merge!(old_set: history_track.original, new_set: history_track.modified)
          Success(change_set)
        end

        def build_payload(change_set, person)
          payload = {}

          primary_family = person.primary_family
          payload.merge!(change_set: change_set, person_hbx_id: person.hbx_id, family_id: primary_family&.id, is_primary: primary_family.present?)
          Success(payload)
        end
      end
    end
  end
end

