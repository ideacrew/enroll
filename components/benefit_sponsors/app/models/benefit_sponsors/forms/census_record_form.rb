module BenefitSponsors
  module Forms
    class CensusRecordForm

      include ActiveModel::Validations
      include Virtus.model

      attribute :employer_assigned_family_id, String
      attribute :employee_relationship, String
      attribute :last_name, String
      attribute :first_name, String
      attribute :middle_name, String
      attribute :name_sfx, String
      attribute :email, String
      attribute :ssn, String
      attribute :dob, String
      attribute :gender, String
      attribute :hire_date, String
      attribute :termination_date, String
      attribute :is_business_owner, String
      attribute :benefit_group, String
      attribute :plan_year, String
      attribute :kind, String
      attribute :address_1, String
      attribute :address_2, String
      attribute :city, String
      attribute :state, String
      attribute :zip, String
      attribute :newly_designated, String

      validates_presence_of :employee_relationship, :email
    end
  end
end
