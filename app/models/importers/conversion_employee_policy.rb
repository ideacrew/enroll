module Importers
  class ConversionEmployeePolicy
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :warnings, :fein, :subscriber_ssn, :subscriber_dob, :benefit_begin_date

    attr_accessor :action,
      :default_policy_start

    include ValueParsers::OptimisticSsnParser.on(:subscriber_ssn, :fein)

    validate :validate_fein
    validate :census_employee
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    def subscriber_dob=(val)
      @subscriber_dob = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
    end

    def benefit_begin_date=(val)
      @benefit_begin_date = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
    end

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def validate_census_employee
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      if found_employee.nil?
        errors.add(:subscriber_ssn, "no census employee found")
      end
    end

    def find_employee
      found_employer = find_employer
      return nil if found_employer.nil?
    end

    def find_employer
      org = Organization.where(:fein => fein).first
      return nil unless org
      org.employer_profile
    end

    def save
      return false unless valid?
      true
    end
  end
end
