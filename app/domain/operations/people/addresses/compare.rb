# frozen_string_literal: true

module Operations
  module People
    module Addresses
      # Class to compare address changes and build payload
      class Compare
        include Dry::Monads[:do, :result]

        # @param [Hash] params
        # @return [Dry::Monads::Result]
        #  Success => {address_id: address_id,
        #   address_set: {original_address: original_set, modified_address: modified_set},
        #   change_set: {old_set: old_set, new_set: new_set}, person_hbx_id: person_hbx_id,
        #   primary_family_id: primary_family_id, is_primary: is_primary}
        def call(params)
          address_id, person_hbx_id = yield validate(params)
          person = yield find_person(person_hbx_id)
          address = yield find_address(address_id, person)
          change_set = yield build_change_set(address)
          address_versions = yield summarized_changes(address, change_set)
          payload = yield build_payload(address_id, address_versions, change_set, person)

          Success(payload)
        end

        private

        def validate(params)
          return Failure("Missing address id ") unless params[:address_id].present?
          return Failure("Missing person hbx id ") unless params[:person_hbx_id].present?
          Success([params[:address_id], params[:person_hbx_id]])
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
          return Failure("change set payload is only applicable for action :update") unless history_track.action.to_sym == :update
          return Failure("No address changes present") unless history_track.original.present? && history_track.modified.present?

          change_set.merge!(old_set: history_track.original, new_set: history_track.modified)
          Success(change_set)
        end

        def summarized_changes(address, change_set)
          original_set = {}
          modified_set = {}
          address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").each_key do |field|
            if change_set[:new_set][field].present? && change_set[:old_set][field].present?
              original_set[field] = change_set[:old_set][field]
              modified_set[field] = change_set[:new_set][field]
            else
              original_set[field] = address.send(field)
              modified_set[field] = address.send(field)
            end
          end
          Success({original_address: original_set, modified_address: modified_set})
        end

        def build_payload(address_id, address_versions, change_set, person)
          payload = {}

          primary_family = person.primary_family
          payload.merge!(address_id: address_id, address_set: address_versions, change_set: change_set, person_hbx_id: person.hbx_id, primary_family_id: primary_family&.id, is_primary: primary_family.present?)
          Success(payload)
        end
      end
    end
  end
end

