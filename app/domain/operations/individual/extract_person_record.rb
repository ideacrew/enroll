# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    class FetchExistingCoverages
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        enrollment           =  yield fetch_enrollment(params[:enrollment_id])
        enrollment_members   =  yield fetch_enrollment_members(enrollment)

        family_ids           =  yield fetch_all_family_ids(enrollment_members)
        prior_enrollments    =  yield prior_enrollments(family_ids, enrollment)

        Success(prior_enrollments)
      end

      private

      def fetch_enrollment(enrollment_id)
        return Failure('Given object is not a valid enrollment object') unless enrollment_id.is_a?(BSON::ObjectId)

        enrollment = ::HbxEnrollment.where(_id: enrollment_id.to_s).first

        enrollment ? Success(enrollment) : Failure('Enrollment not found')
      end

      def fetch_enrollment_members(enrollment)
        members = enrollment.hbx_enrollment_members
        members.count > 0 ? Success(members) : Failure('Enrollment does not include dependents')
      end

      def fetch_all_family_ids(enrollment_members)
        family_ids = []
        enrollment_members.each do |enr_member|
          person = enr_member.person
          family_ids << Family.find_all_by_person(person).pluck(:id).to_s
        end
        family_ids.count > 0 ? Success(family_ids.uniq) : Failure('No families found for members')
      end

      def prior_enrollments(family_ids, enrollment)
        all_enrollments = HbxEnrollment.where({:family_id.in => family_ids, coverage_kind: enrollment.coverage_kind, market_kind: enrollment.market_kind}).enrolled_and_renewing
        existing_enrollments = all_enrollments - enrollment

        Success(existing_enrollments)
      end
    end
  end
end
