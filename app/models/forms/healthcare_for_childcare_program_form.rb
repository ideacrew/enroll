module Forms
  class HealthcareForChildcareProgramForm

    include ActiveModel::Model

    attr_accessor :osse_eligibility

    def load_consumer(person)
      @consumer_role = person.consumer_role
      @osse_eligibility = false
    end
    
    def submit
      #@consumer_role.create_eligibility(eligibility_params)
    end

    private

    def eligibility_params
      {
        evidence_key: :osse_subsidy,
        evidence_value: osse_eligibility,
        effective_date: TimeKeeper.date_of_record
      }
    end
  end
end