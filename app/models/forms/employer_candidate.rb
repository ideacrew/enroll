module Forms
  class EmployerCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include FeinField
    include EmployerFields

    validates_presence_of :fein, :allow_blank => nil
    validates_presence_of :legal_name, :allow_blank => nil

    validates :fein,
              length: { minimum: 9, maximum: 9, message: " must be 9 digits" },
              numericality: true

    def match_employer
      EmployerProfile.find_by_fein(fein)
    end

    def persisted?
      false
    end
  end
end
