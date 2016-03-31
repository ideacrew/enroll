module Importers
  class ConversionEmployer
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :fein, :broker_npn, :primary_location_zip, :mailing_location_zip

    attr_accessor :action,
      :dba,
      :legal_name,
      :primary_location_address_1,
      :primary_location_address_2,
      :primary_location_city,
      :primary_location_state,
      :mailing_location_address_1,
      :mailing_location_address_2,
      :mailing_location_city,
      :mailing_location_state,
      :contact_email,
      :contact_phone,
      :enrolled_employee_count,
      :new_hire_count,
      :broker_name,
      :contact_first_name,
      :contact_last_name,
      :registered_on

    include Validations::Email

    validates :contact_email, :email => true, :allow_blank => true
    validates_presence_of :contact_first_name, :allow_blank => false
    validates_presence_of :contact_last_name, :allow_blank => false
    validates_presence_of :legal_name, :allow_blank => false
    validates_length_of :fein, is: 9

    validate :validate_new_fein
    validate :broker_exists_if_specified

    attr_reader :warnings

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    def fein=(val)
      if val.blank?               
        @fein = nil
      else                                              
        stripped_value = val.strip.gsub(/\D/, "").rjust(9, "0")       
        if (stripped_value == "000000000")                                      
          @fein = nil
        else
          @fein = stripped_value
        end
      end 
    end

    def broker_npn=(val)
      @broker_npn = Maybe.new(val).strip.extract_value
    end

    def validate_new_fein
      return true if fein.blank?
      if Organization.where(:fein => fein).any?
        errors.add(:fein, "is already taken")
      end
    end

    def broker_exists_if_specified
      return true if broker_npn.blank?
      unless BrokerRole.by_npn(broker_npn).any?
        warnings.add(:broker_npn, "does not correspond to an existing Broker")
      end
    end

    def map_office_locations
      locations = []
      main_address = Address.new(
        :kind => "work",
        :address_1 => primary_location_address_1,
        :address_2 => primary_location_address_2,
        :city =>  primary_location_city,
        :state => primary_location_state,
        :zip => primary_location_zip
      )
      mailing_address = Address.new(
        :kind => "mailing",
        :address_1 => mailing_location_address_1,
        :address_2 => mailing_location_address_2,
        :city =>  mailing_location_city,
        :state => mailing_location_state,
        :zip => mailing_location_zip
      )
      main_location = OfficeLocation.new({
        :address => main_address,
        :phone => Phone.new({
          :kind => "work",
          :full_phone_number => contact_phone
        }),
        :is_primary => true 
      })
      locations << main_location
      if !mailing_address.blank?
        if !mailing_address.same_address?(main_address)
          locations << OfficeLocation.new({
            :is_primary => false,
            :address => mailing_address
          })
        end
      end
      locations
    end

    ["primary", "mailing"].each do |item|
      class_eval(<<-RUBY_CODE)
      def #{item}_location_zip=(val)
        if val.blank?
          @#{item}_location_zip = nil
          return val
        else
          if val.strip.length == 9 
            @#{item}_location_zip = val[0..4]
          else
            @#{item}_location_zip = val.strip.rjust(5, "0")
          end 
        end
      end
      RUBY_CODE
    end

    def assign_brokers
      broker_agency_accounts = []
      if !broker_npn.blank?
        br = BrokerRole.by_npn(broker_npn).first
        if !br.nil?
          broker_agency_accounts << BrokerAgencyAccount.new({
            start_on: Time.mktime(2016,4,1,0,0,0),
            writing_agent_id: br.id,
            broker_agency_profile_id: br.broker_agency_profile_id
          })
        end
      end 
      broker_agency_accounts
    end

    def map_poc(emp)
      person_attrs = {
        :first_name => contact_first_name,
        :last_name => contact_last_name,
        :employer_staff_roles => [
          EmployerStaffRole.new(employer_profile_id: emp.id)
        ],
        :phones => [
          Phone.new({
            :kind => "work",
            :full_phone_number => contact_phone
          })
        ]
      }
      if !contact_email.blank?
        person_attrs[:emails] = [
          Email.new(:kind => "work", :address => contact_email)
        ]
      end
      Person.create!(person_attrs)
    end

    def save
      return false unless valid?
      new_organization = Organization.new({
        :fein => fein,
        :legal_name => legal_name,
        :dba => dba,
        :office_locations => map_office_locations,
        :employer_profile => EmployerProfile.new({
          :broker_agency_accounts => assign_brokers,
          :entity_kind => "c_corporation",
          :profile_source => "conversion",
          :registered_on => registered_on
        })
      })
      save_result = new_organization.save
      if save_result
        emp = new_organization.employer_profile
        map_poc(emp)
      end
      propagate_errors(new_organization)
      return save_result
    end

    def propagate_errors(org)
      org.errors.each do |attr, err|
        errors.add(attr, err)
      end
      org.office_locations.each_with_index do |office_location, idx|
        office_location.errors.each do |attr, err|
          errors.add("office_location_#{idx}_" + attr.to_s, err)
        end
      end
    end
  end
end
