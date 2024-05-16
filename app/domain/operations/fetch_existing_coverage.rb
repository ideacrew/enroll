# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
    # get active enrollments based on family_ids, aasm_state, market kind && coverage kind.
  class FetchExistingCoverage
    include Dry::Monads[:do, :result]

    def call(params)
      values               =  yield validate(params)
      enrollment           =  yield fetch_enrollment(values)
      enrollment_members   =  yield fetch_enrollment_members(enrollment)

      family_ids           =  yield fetch_all_family_ids(enrollment_members)
      prior_enrollments    =  yield prior_enrollments(family_ids, enrollment)

      Success(prior_enrollments)
    end

    private

    def validate(params)
      return Failure("Given input is not a valid enrollment id") unless params[:enrollment_id].is_a?(BSON::ObjectId)

      Success(params)
    end

    def fetch_enrollment(values)
      enrollment = ::HbxEnrollment.where(_id: values[:enrollment_id].to_s)
      enrollment.present? ? Success(enrollment) : Failure("Enrollment Not Found")
    end

    def fetch_enrollment_members(enrollment)
      members = enrollment.first.hbx_enrollment_members
      members.count > 0 ? Success(members) : Failure('Enrollment does not include dependents')
    end

    def fetch_all_family_ids(enrollment_members)
      family_ids = []
      enrollment_members.each do |enr_member|
        person = enr_member&.person
        family_ids << Family.find_all_by_person(person).pluck(:id) if person.present?
      end
      family_ids.count > 0 ? Success(family_ids.uniq.flatten) : Failure('No families found for members')
    end

    def prior_enrollments(family_ids, enrollment)
      all_enrollments = HbxEnrollment.where({:family_id.in => family_ids, :aasm_state => {"$in" => HbxEnrollment::ENROLLED_STATUSES }, coverage_kind:  enrollment.first.coverage_kind, kind:  enrollment.first.kind})
      existing_enrollments = all_enrollments - enrollment
      Success(existing_enrollments)
    end

  end
end



