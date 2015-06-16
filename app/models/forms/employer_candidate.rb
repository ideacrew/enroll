module Forms
  class EmployerCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include FeinField
    include EmployerFields

    validates_presence_of :fein, :allow_blank => nil
    validates_presence_of :legal_name, :allow_blank => nil

    validate :does_not_match_a_company_with_existing_owner

    validates :fein,
              length: { minimum: 9, maximum: 9, message: " must be 9 digits" },
              numericality: true

    def match_employer
      ::EmployerProfile.find_by_fein(fein)
    end

    def does_not_match_a_company_with_existing_owner
      if match_employer.present? && match_employer.owner.present?
        errors.add(
          :exception,
          "This company already has a managing owner"
          )
      end

      true
    end

  end
end
