module Importers
  class ConversionEmployer
    include ActiveModel::Validations
    include ActiveModel::Model
    include ::Etl::ValueParsers

    attr_converter :fein, :as => :optimistic_ssn
    # used for GA but it is not there in MA
    # attr_converter :tpa_fein, :as => :optimistic_ssn

    attr_reader :corporate_npn, :primary_location_zip, :mailing_location_zip

    attr_accessor :action,
                  :dba,
                  :legal_name,
                  :primary_location_address_1,
                  :primary_location_address_2,
                  :primary_location_city,
                  :primary_location_state,
                  :primary_location_county,
                  :mailing_location_address_1,
                  :mailing_location_address_2,
                  :mailing_location_city,
                  :mailing_location_state,
                  :contact_email,
                  :contact_phone,
                  :contact_phone_extension,
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
    # validate :validate_tpa_if_specified

    attr_reader :warnings

    def initialize(opts = {})
      super(opts)
      @warnings ||= ActiveModel::Errors.new(self)
    end

    def corporate_npn=(val)
      @corporate_npn = Maybe.new(val).strip.extract_value
    end

    def validate_tpa_if_specified
      return true if corporate_npn.blank?
      return true if tpa_fein.blank?
      unless find_broker
        warnings.add(:tpa_fein, "specified, but could not find Broker")
      end
      unless find_ga
        warnings.add(:tpa_fein, "is not an existing General Agency")
        if find_broker
          found_ga = find_broker.broker_agency_profile.default_general_agency_profile
          unless found_ga
            warnings.add(:tpa_fein, "can not be assigned from broker default - broker doesn't have one")
          end
        else
          warnings.add(:tpa_fein, "can not be assigned from broker default - no broker")
        end
      end
    end

    def find_broker
      return nil if corporate_npn.blank?
      BenefitSponsors::Organizations::BrokerAgencyProfile.where(corporate_npn: corporate_npn).first
    end

    def fein=(val)
      @fein = prepend_zeros(val.to_s.gsub('-', '').strip, 9)
    end

    def validate_new_fein
      return true if fein.blank?
      found_org = Organization.where(:fein => fein).first
      if found_org
        if found_org.employer_profile
          errors.add(:fein, "is already taken")
        else
          warnings.add(:fein, "already exists for organization, but does not have an employer profile")
        end
      end
    end

    def broker_exists_if_specified
      return true if corporate_npn.blank?
      broker_agency = BenefitSponsors::Organizations::BrokerAgencyProfile.where(corporate_npn: corporate_npn).first
      unless broker_agency.present?
        warnings.add(:broker_npn, "does not correspond to an existing Broker")
      end
    end


    def fetch_entity_kind
      # In excel we do not have that field we are making default to "c-corporation"
      :c_corporation
    end

    def map_poc(emp)
      person_attrs = {
          :first_name => contact_first_name,
          :last_name => contact_last_name,
          :employer_staff_roles => [
              EmployerStaffRole.new(benefit_sponsor_employer_profile_id: emp.id, is_owner: false)
          ],
          :phones => [
              Phone.new({
                            :kind => "work",
                            :full_phone_number => contact_phone
                        })
          ]
      }
      if !contact_email.blank?
        emails = contact_email.strip.split(',')
        person_attrs[:emails] = emails.map {|email| Email.new(:kind => "work", :address => email.gsub(/\s/, ''))}
      end
      Person.create!(person_attrs)
    end

=begin
    def update_poc(emp)
      return true if contact_first_name.blank? || contact_last_name.blank?

      matching_staff_role = emp.staff_roles.detect {|staff|
        staff.first_name.match(/#{contact_first_name}/i) && staff.last_name.match(/#{contact_last_name}/i)
      }

      if emp.staff_roles.present? && matching_staff_role.blank?
        emp.staff_roles.each do |person|
          person.employer_staff_roles.where(employer_profile_id: emp.id).each {|role| role.close_role!}
        end
      end

      if matching_staff_role.present?
        matching_staff_role.phones = [
            Phone.new({
                          :kind => "work",
                          :full_phone_number => contact_phone
                      })
        ]

        if contact_email.present?
          matching_staff_role.emails = [
              Email.new(:kind => "work", :address => contact_email)
          ]
        end

        matching_staff_role.save!
      else
        map_poc(emp)
      end
    end
=end

    def build_primary_address
      BenefitSponsors::Locations::Address.new(
          :kind => "work",
          :address_1 => primary_location_address_1,
          :address_2 => primary_location_address_2,
          :city => primary_location_city,
          :state => primary_location_state,
          :county => primary_location_county,
          :zip => primary_location_zip
      )
    end

    def build_mailing_address
      BenefitSponsors::Locations::Address.new(
          :kind => "mailing",
          :address_1 => mailing_location_address_1,
          :address_2 => mailing_location_address_2,
          :city => mailing_location_city,
          :state => mailing_location_state,
          :zip => mailing_location_zip
      )
    end

    def build_phone
      BenefitSponsors::Locations::Phone.new({
                                                :kind => "work",
                                                :full_phone_number => contact_phone
                                            })
    end

    def map_office_locations
      locations = []
      primary_address = build_primary_address
      mailing_address = build_mailing_address
      locations << BenefitSponsors::Locations::OfficeLocation.new({
                                                                      :is_primary => true,
                                                                      :address => primary_address,
                                                                      :phone => build_phone,
                                                                  })
      unless primary_location_address_1 == mailing_location_address_1
        locations << BenefitSponsors::Locations::OfficeLocation.new({
                                                                        :is_primary => false,
                                                                        :address => mailing_address,
                                                                    })

      end
      locations
    end

    def propagate_errors(employer_profile)
      employer_profile.errors.each do |attr, err|
        errors.add(attr, err)
      end
      employer_profile.office_locations.each_with_index do |office_location, idx|
        office_location.errors.each do |attr, err|
          errors.add("office_location_#{idx}_" + attr.to_s, err)
        end
      end
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times {number.prepend('0')}
      number
    end
  end
end
