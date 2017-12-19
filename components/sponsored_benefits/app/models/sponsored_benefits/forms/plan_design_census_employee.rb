module SponsoredBenefits
  module Forms
    class PlanDesignCensusEmployee
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :first_name, :last_name, :ssn, :dob

      def save
        census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployeeBuilder.build do |builder|
          builder.add_first_name(first_name)
          builder.add_last_name(last_name)
          builder.add_ssn(ssn)
          builder.add_dob(dob)
          builder.add_dependent(dependent)
        end

        census_employee.save
      end
    end
  end
end
