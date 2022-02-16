# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    class ExtractPersonRecord
      send(:include, Dry::Monads[:result, :do])

      def call(enrollment_id:)
        enrollment           =  yield fetch_enrollment(enrollment_id)
        enrollment_members   =  yield fetch_enrollment_members(enrollment)

        family_ids           =  yield fetch_family_ids(enrollment_members)
        prior_enrollments    =  yield prior_enrollments(family_ids)
      end

      private

      def fetch_enrollment(enrollment_id)
        return Failure('Given object is not a valid enrollment object') unless enrollment_id.is_a?(BSON::ObjectId)

        enrollment = ::HbxEnrollment.where(_id: enrollment_id.to_s).first

        enrollment ? Success(enrollment) : Failure('Enrollment not found')
      end

      def fetch_enrollment_members(enrollment)
        members = enrollment.hbx_enrollment_members
        if members&.present?
          Success(members)
        else
          Failure('Hbx Enrollment members not found')
        end
      end

      def fetch_family_ids(enrollment_members)
        family_ids = []
        enrollment_members.each do |hem|
          person = hem.person
          family_ids << Family.find_all_by_person(person).pluck(:id)
        end
        family_ids.uniq
      end

      def prior_enrollments(family_ids)
        enrollments_list = []
        family_ids.each do |fam_id|
          enrollments = HbxEnrollment.where({
                                        :family_id => fam_id.to_s
                                      }).enrolled_and_renewing
       end
       enrollments_list
      end
    end
  end
end
