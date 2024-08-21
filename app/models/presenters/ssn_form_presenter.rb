# frozen_string_literal: true

module Presenters
  # arrange some of the form object data to move more logic out of the frontend
  class SsnFormPresenter
    include ::ApplicationHelper

    attr_reader :obscured_ssn,
                :object_type,
                :disabled,
                :person_id,
                :family_id

    def initialize(form_object, family_id = nil)
      @form_object = form_object

      @object_type = @form_object.class.to_s
      @obscured_ssn = nil
      @family_id = family_id ? family_id.to_s : nil
      @person_id = nil
      @disabled = nil
    end

    def sanitize_ssn_params
      case @object_type
      when 'Forms::ConsumerCandidate'
        sanitize_new_consumer
      when 'Forms::FamilyMember'
        sanitize_family_dependent
      when 'Person'
        sanitize_person
      when 'FinancialAssistance::Applicant'
        sanitize_applicant
      end
      self
    end

    def formatted_ssn
      @object_type == 'Forms::ConsumerCandidate' ? number_to_ssn(@form_object.ssn) : ''
    end

    private

    def sanitize_new_consumer
      obscure_ssn

      @person_id = 'temp'
      @disabled = true
    end

    def sanitize_person
      obscure_ssn
      @person_id = @form_object.id.to_s
      @family_id ||= @form_object.primary_family.id.to_s
      @disabled = true
    end

    def sanitize_family_dependent
      obscure_ssn

      @family_id = @form_object.family_id.to_s
      family_member = @form_object.family_member

      @person_id = family_member.person_id.to_s
      @disabled = family_member.is_primary_applicant
    end

    def sanitize_applicant
      family = @form_object.family
      @family_id = family.id.to_s

      person = Person.by_hbx_id(@form_object.person_hbx_id).first
      @person_id = person.id.to_s

      obscure_ssn(person)
      @disabled = @form_object.is_primary_applicant?
    end

    def obscure_ssn(subject = @form_object)
      clone_ssn = subject.ssn.dup
      @obscured_ssn = number_to_obscured_ssn(clone_ssn)
    end
  end
end
