module Validations
  module ConsumerInformation
    def self.included(klass)
      klass.class_eval do 
        validates :ssn,
          length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
          numericality: true,
          uniqueness: true,
          allow_blank: true
        validates :gender,
            allow_blank: true,
            inclusion: { in: Person::GENDER_KINDS, message: "%{value} is not a valid gender" }
      end
    end
  end
end
