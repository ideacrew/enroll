module Importers
  class ConversionEmployee
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :warnings, :fein, :subscriber_ssn, :subscriber_dob, :subscriber_gender, :hire_date

    attr_accessor :action,
      :employer_name,
      :benefit_begin_date,
      :subscriber_gender,
      :subscriber_name_first,
      :subscriber_name_middle,
      :subscriber_name_last,
      :subscriber_email,
      :subscriber_phone,
      :subscriber_address_1,
      :subscriber_address_2,
      :subscriber_city,
      :subscriber_state,
      :subscriber_zip,
      :default_hire_date

      (1..8).to_a.each do |num|
        attr_reader "dep_#{num}_ssn".to_sym, "dep_#{num}_dob".to_sym, "dep_#{num}_gender".to_sym
      end
      (1..8).to_a.each do |num|
        attr_accessor "dep_#{num}_name_first".to_sym,
          "dep_#{num}_name_middle".to_sym,
          "dep_#{num}_name_last".to_sym,
          "dep_#{num}_email".to_sym,
          "dep_#{num}_phone".to_sym,
          "dep_#{num}_address_1".to_sym,
          "dep_#{num}_address_2".to_sym,
          "dep_#{num}_city".to_sym,
          "dep_#{num}_state".to_sym,
          "dep_#{num}_zip".to_sym,
          "dep_#{num}_relationship".to_sym
      end

      validate :validate_fein
      validates_length_of :fein, is: 9

      def initialize(opts = {})
        super(opts)
        @warnings = ActiveModel::Errors.new(self)
      end

      def subscriber_ssn=(val)
        @subscriber_ssn = Maybe.new(val).strip.gsub(/\D/, "").extract_value
      end

      def hire_date=(val)
        @hire_date = val.blank? ? nil : (self.dob.strftime("%m/%d/%Y") rescue nil)
      end

      def subscriber_dob=(val)
        @subscriber_dob = val.blank? ? nil : (self.dob.strftime("%m/%d/%Y") rescue nil)
      end

      def subscriber_gender=(val)
        @subscriber_gender = Maybe.new(val).strip.downcase.extract_value
      end

      (1..8).to_a.each do |num|
        class_eval(<<-RUBYCODE)
          def dep_#{num}_ssn=(val)
            @dep_#{num}_ssn = Maybe.new(val).strip.gsub(/\D/, "").extract_value
          end

          def dep_#{num}_gender=(val)
            @dep_#{num}_gender = Maybe.new(val).strip.downcase.extract_value
          end

          def dep_#{num}_dob=(val)
            @dep_#{num}_dob = val.blank? ? nil : (self.dob.strftime("%m/%d/%Y") rescue nil)
          end
        RUBYCODE
      end

      def map_subscriber
        last_name = subscriber_name_last
        first_name = subscriber_name_first
        middle_name = subscriber_name_middle
        dob = subscriber_dob
        gender = subscriber_gender
        ssn = subscriber_ssn
        email = subscriber_email
        address_1 = subscriber_address_1
        address_2 = subscriber_address_2
        city = subscriber_city
        state = subscriber_state
        zip = subscriber_zip
        attr_hash = {
         first_name: first_name,
         last_name: last_name,
         dob: dob,
         gender: gender
        }
        if hire_date.blank?
          attr_hash[:hired_on] = default_hire_date
        else
          attr_hash[:hired_on] = hire_date
        end
        unless middle_name.blank?
          attr_hash[:middle_name] = middle_name
        end
        unless ssn.blank?
          attr_hash[:ssn] = ssn
        end
        unless email.blank?
          attr_hash[:email] = Email.new(:kind => work, :address => email)
        end
        unless address_1.blank?
          addy_attr = {
            kind: "home",
            city: city,
            state: state,
            address_1: address_1,
            zip: zip
          }
          unless address_2.blank?
            addy_attr[:address_2] = address_2
          end
          attr_hash[:address] = Address.new(addy_attr)
        end
        CensusEmployee.new(attr_hash)
      end

      def map_dependent(dep_idx)
        last_name = self.send("dep_#{dep_idx}_name_last".to_sym)
        first_name = self.send("dep_#{dep_idx}_name_first".to_sym)
        middle_name = self.send("dep_#{dep_idx}_name_middle".to_sym)
        relationship = self.send("dep_#{dep_idx}_relationship".to_sym)
        dob = self.send("dep_#{dep_idx}_dob".to_sym)
        ssn = self.send("dep_#{dep_idx}_ssn".to_sym)
        gender = self.send("dep_#{dep_idx}_gender".to_sym)
        if [first_name, last_name, middle_name, relationship, dob, ssn, gender].all?(&:blank?)
          return nil
        end
        attr_hash = {
         first_name: first_name,
         last_name: last_name,
         dob: dob,
         employee_relationship: relationship,
         gender: gender
        }
        unless middle_name.blank?
          attr_hash[:middle_name] = middle_name
        end
        unless ssn.blank?
          attr_hash[:ssn] = ssn
        end
        CensusDependent.new(attr_hash)
      end

      def map_dependents
        (1..8).to_a.map do |idx|
          map_dependent(idx)
        end.compact
      end

      def fein=(val)
        @fein = Maybe.new(val).strip.gsub(/\D/, "").extract_value
      end

      def validate_fein
        return true if fein.blank?
        found_employer = find_employer
        if found_employer.nil?
          errors.add(:fein, "does not exist")
        end
      end

      def find_employer
        org = Organization.where(:fein => fein).first
        return nil unless org
        org.employer_profile
      end

      def save
        return false unless valid?
        census_employee = map_subscriber
        census_employee.employer_profile = find_employer
        census_employee.census_dependents = map_dependents
        save_result = census_employee.save
        unless save_result
          propagate_errors(census_employee)
        end
        return save_result
      end

      def propagate_errors(census_employee)
        census_employee.errors.each do |attr, err|
          errors.add("census_employee_" + attr.to_s, err)
        end
        census_employee.census_dependents.each_with_index do |c_dep, idx|
          c_dep.errors.each do |attr, err|
            errors.add("dependent_#{idx}_" + attr.to_s, err)
          end
        end
      end
  end
end
