# frozen_string_literal: true

module Forms
  # Form model for child care subsidy
  class HealthcareForChildcareProgramForm
    include ActiveModel::Model

    attr_accessor :osse_eligibility, :role

    def load_eligibility(person)
      @role = if person.has_active_resident_role?
                person.resident_role
              elsif person.has_active_consumer_role?
                person.consumer_role
              end

      @osse_eligibility = person_osse_eligible?
    end

    def submit(params)
      @osse_eligibility = params[:osse_eligibility]
      return "OSSE eligibility already exists!" if osse_eligibility == 'true' && person_osse_eligible?
      @role.create_or_term_eligibility(eligibility_params)
    end

    class << self
      def build_forms_for(family)
        family.active_family_members.inject({}) do |forms, family_member|
          form = self.new
          form.load_eligibility(family_member.person)
          forms[family_member.person] = form
          forms
        end
      end

      def submit_with(params)
        person = Person.find(params[:person_id])
        form = self.new
        form.load_eligibility(person)
        form.submit(params)
      end
    end

    private

    def person_osse_eligible?(date = ::TimeKeeper.date_of_record)
      @role.is_osse_eligibility_satisfied?(date)
    end

    def eligibility_params
      {
        evidence_key: :osse_subsidy,
        evidence_value: @osse_eligibility,
        effective_date: ::TimeKeeper.date_of_record
      }
    end
  end
end