module Forms
  class HealthcareForChildcareProgramForm

    include ActiveModel::Model

    attr_accessor :osse_eligibility

    def load_consumer(person)
      @consumer_role = person.consumer_role
      @osse_eligibility = false
      #@osse_eligibility = consumer_role.eligible_for?(:osse_subsidy, TimeKeeper.date_of_record)
    end
    
    def submit
      @consumer_role.create_eligibility(eligibility_params)
    end
  end
end