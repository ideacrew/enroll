# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Households
    # checks existing shop coverage in enroll for a person
    class CheckExistingCoverageByPerson
      include Dry::Monads[:do, :result]

      def call(*args)
        args = args.first
        person_hbx_id      = yield validate(args[:person_hbx_id])
        person             = yield find_person(person_hbx_id)
        family_ids         = yield fetch_all_family_ids(person)
        query              = yield query_builder(args.merge(family_ids: family_ids))
        prior_enrollments  = yield existing_coverage(query, person_hbx_id)

        Success(prior_enrollments)
      end

      private

      def validate(id)
        if id.present? & (id.is_a?(BSON::ObjectId) || id.is_a?(String))
          Success(id)
        else
          Failure('id is nil or not in BSON format')
        end
      end

      def find_person(person_hbx_id)
        person = Person.by_hbx_id(person_hbx_id).first
        person.present? ? Success(person) : Failure("Unable to find Person with ID #{person_hbx_id}.")
      rescue StandardError
        Failure("Unable to find Person with ID #{person_hbx_id}.")
      end

      def fetch_all_family_ids(person)
        family_ids = []
        family_ids << Family.find_all_by_person(person).pluck(:id) if person.present?
        family_ids.flatten.uniq.count > 0 ? Success(family_ids.uniq.flatten) : Failure('No families found for person')
      end

      def query_builder(params)
        eligibile_statuses = HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::WAIVED_STATUSES
        query = {:family_id => {"$in" => params[:family_ids]},
                 :aasm_state => {"$in" => eligibile_statuses }}

        query.merge!(kind: params[:market_kind]) if params[:market_kind].present?
        Success(query)
      end

      def existing_coverage(query, person_hbx_id)
        existing_enrollments = HbxEnrollment.where(query)
        existing_enrollments = existing_enrollments.select do |enrollment|
          enrollment.hbx_enrollment_members.map(&:person).flatten.map(&:hbx_id).flatten.include?(person_hbx_id)
        end
        Success(existing_enrollments)
      end
    end
  end
end
