# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps

    # embeds_one :enrollment_period

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :is_satisfied, type: Boolean, default: false
    field :has_unsatisfied_evidences, type: Boolean, default: true
    field :effective_date, type: Date

    field :object_klass, type: String
    field :is_eligible, type: Boolean, default: false

    field :due_date, type: DateTime
    field :has_unsatisfied_evidences, type: Boolean, default: true

    embeds_many :evidences, class_name: 'Eligibilities::Evidence'

    before_save :update_evidence_status

    # verification_period_length = 90.days

  #   hbx_enrollment_meta = {
  #     klass: HbxEnrollment,
  #     id: id,
  #     evidences: [:member_enrolled]
  #   }

  #   faa_application_meta = {
  #     klass: FaaApplication,
  #     id: id,
  #   }


  #  object_klass: Faa::Application,

  #   FamilyMembers.consumer_roles.evidences == is_satisfied

  #   FaaApplication.applicants.evidence == is_satisfied



  #   HbxEnrollment.members.evidences == is_satisfied
  #   TaxHousehold.evidences == is_satisfied

  #   FaaApplicationRenewal.applicants.evidence == is_satisfied
  #   HbxEnrollmentRenewal.members.evidences == is_satisfied


  #   FamilyMembers.each  |member| member. }

    def evidences
    end


    def visit_evidence(evidence_meta, id)

    end

    def visit_all_evidences(instance)
    end

    # scope :eligibility_verifications_outstanding

    def unsatisfied_evidences
      evidences.reduce([]) do |list, evidence|
        list << evidence unless evidence.is_satisfied
        list
      end
    end

    private

    def update_evidence_status
      if unsatisfied_evidences.empty?
        write_attribute(:has_unsatisfied_evidences, false)
      else
        write_attribute(:has_unsatisfied_evidences, true)
      end
    end
  end
end
