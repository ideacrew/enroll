module SponsoredBenefits
  module Forms
    class PlanDesignCensusEmployee
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :first_name, :middle_name, :last_name, :ssn, :gender, :dob, :employee_relationship


      def save
        census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployeeBuilder.build do |builder|
          builder.add_dependent(dependent)
        end

        census_employee.save
      end
    end
  end
end
