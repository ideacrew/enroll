# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
module FinancialAssistance
  module Forms
    class Applicant
      include ActiveModel::Model
      include ActiveModel::Validations
      include Config::AcaModelConcern
      include AddressValidator

      attr_accessor :id, :family_id, :is_consumer_role, :is_resident_role, :vlp_document_id, :application_id, :applicant_id, :gender, :relationship, :relation_with_primary, :no_dc_address, :is_homeless, :is_temporarily_out_of_state,
                    :tribe_codes, :same_with_primary, :is_applying_coverage, :immigration_doc_statuses, :addresses, :phones, :emails, :addresses_attributes, :phones_attributes, :emails_attributes, :is_dependent

      attr_writer :family

      include FinancialAssistance::Forms::PeopleNames
      include FinancialAssistance::Forms::ConsumerFields
      include FinancialAssistance::Forms::SsnField
      include FinancialAssistance::Forms::DateOfBirthField

      RELATIONSHIPS = FinancialAssistance::Relationship::RELATIONSHIPS + ::BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS

      validates_presence_of :first_name, :allow_blank => nil
      validates_presence_of :last_name, :allow_blank => nil
      validates_presence_of :gender, :allow_blank => nil
      validates_presence_of :dob
      validates :ssn,
                length: {minimum: 9, maximum: 9, message: " must be 9 digits"},
                allow_blank: true,
                numericality: true
      # validates_inclusion_of :relationship, :in => RELATIONSHIPS.uniq, :allow_blank => nil, message: ""
      validate :relationship_validation
      validate :consumer_fields_validation
      validate :check_same_ssn

      attr_reader :dob

      def initialize(*attributes)
        initialize_attributes
        super
      end

      def initialize_attributes
        @addresses = %w[home mailing].collect{|kind| FinancialAssistance::Locations::Address.new(kind: kind) }
        @phones    = FinancialAssistance::Locations::Phone::KINDS.collect{|kind| FinancialAssistance::Locations::Phone.new(kind: kind) }
        @emails    = FinancialAssistance::Locations::Email::KINDS.collect{|kind| FinancialAssistance::Locations::Email.new(kind: kind) }

        @same_with_primary = "true"
        @is_applying_coverage = true
      end

      def consumer_fields_validation
        return true unless individual_market_is_enabled?
        return unless @is_consumer_role.to_s == "true" && is_applying_coverage.to_s == "true"

        validate_citizen_status

        self.errors.add(:base, "native american / alaska native status is required") if @indian_tribe_member.nil?
        validate_tribe_details if @indian_tribe_member

        self.errors.add(:base, "Incarceration status is required") if @is_incarcerated.nil?
      end

      def validate_citizen_status
        error_message = if @us_citizen.nil?
                          "Citizenship status is required"
                        elsif @us_citizen == false && (@eligible_immigration_status.nil? && EnrollRegistry[:immigration_status_question_required].item)
                          "Eligible immigration status is required"
                        elsif @us_citizen == true && @naturalized_citizen.nil?
                          "Naturalized citizen is required"
                        end
        self.errors.add(:base, error_message) if error_message.present?
      end

      def validate_tribe_details
        if EnrollRegistry[:indian_alaskan_tribe_details].enabled?
          self.errors.add(:tribal_state, "is required when native american / alaska native is selected") unless tribal_state.present?
          validate_featured_tribes if FinancialAssistanceRegistry[:featured_tribes_selection].enabled?
          self.errors.add(:tribal_name, "is required when native american / alaska native is selected") if !tribal_name.present? && !FinancialAssistanceRegistry[:featured_tribes_selection].enabled?
          self.errors.add(:tribal_name, "cannot contain numbers") unless (tribal_name =~ /\d/).nil?
        else
          self.errors.add(:tribal_id, "is required when native american / alaska native is selected") unless tribal_id.present?
          self.errors.add(:tribal_id, "Tribal id must be 9 digits") if tribal_id.present? && !tribal_id.match("[0-9]{9}")
        end
      end

      def validate_featured_tribes
        if tribal_state == EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
          self.errors.add(:tribal_name, "is required when native american / alaska native is selected") if tribe_codes.include?("OT") && !tribal_name.present?
          self.errors.add(:base, "At least one tribe must be selected") if tribe_codes.empty?
        else
          self.errors.add(:tribal_name, "is required when native american / alaska native is selected") unless tribal_name.present?
        end
      end

      def persisted?
        return false unless applicant
        applicant.persisted?
      end

      def application
        return @application if defined? @application
        @application = FinancialAssistance::Application.find(application_id) if application_id.present?
      end

      def applicant
        return @applicant if defined? @applicant
        @applicant = application.applicants.find(applicant_id) if applicant_id.present?
      end

      # Checks if the given address should be destroyed.
      #
      # This method checks if the address is of kind 'mailing', if it is marked for destruction, and if it has an id.
      #
      # @param address [Hash] the address to check
      # @option address [String] :kind the kind of the address
      # @option address [String] :_destroy whether the address is marked for destruction ('true' or 'false')
      # @option address [String, nil] :id the id of the address, or nil if it doesn't have one
      #
      # @return [Boolean] true if the address should be destroyed, false otherwise
      def destroy_mailing_address?(address)
        address[:kind] == FinancialAssistance::Locations::Address::MAILING_KIND && address[:_destroy] == 'true' && address[:id].present?
      end

      def save
        return false unless valid?
        is_living_in_state = has_in_state_home_addresses?(addresses_attributes)
        applicant_entity = FinancialAssistance::Operations::Applicant::Build.new.call(params: extract_applicant_params.merge(is_living_in_state: is_living_in_state))

        if applicant_entity.success?
          values = applicant_entity.success.to_h.except(:addresses, :emails, :phones).merge(nested_parameters)
          applicant = application.applicants.find(applicant_id) if applicant_id.present?
          if applicant.present? && applicant.persisted?
            applicant.home_address&.destroy if applicant.is_dependent? && same_with_primary == "true"

            # Destroys mailing address if it is marked for destroy.
            applicant.mailing_address.destroy! if applicant.mailing_address.present? && addresses_attributes.values.any? { |address| destroy_mailing_address?(address) }

            applicant.update(values)
          else
            applicant = application.applicants.build(values)
            applicant.save!
          end

          # reloading the application to fetch the latest data updated through applicant callbacks to avoid duplicate relationships
          application.reload
          application.ensure_relationship_with_primary(applicant, relationship) if relationship.present?
          [true, applicant]
        else
          applicant_entity.failure.collect{|key, msg| "#{key} #{msg[0]}"}.each do |error_msg|
            errors.add(:base, error_msg)
          end
          [false, applicant_entity.failure]
        end
      end

      def update_relationship_and_relative_relationship(relationship)
        self&.applicant&.relationships&.last&.update_attributes(kind: relationship)
        self&.applicant&.relationships&.last&.relative&.relationships&.where(relative_id: self.applicant.id)&.first&.update_attributes(kind: FinancialAssistance::Relationship::INVERSE_MAP[relationship])
      end

      def extract_applicant_params
        assign_citizen_status

        attrs = {
          first_name: first_name,
          last_name: last_name,
          middle_name: middle_name,
          gender: gender,
          dob: dob,
          ssn: ssn,
          no_ssn: no_ssn,
          is_consumer_role: is_consumer_role,
          is_homeless: is_homeless,
          is_incarcerated: is_incarcerated,
          same_with_primary: same_with_primary,
          is_applying_coverage: is_applying_coverage,
          ethnicity: ethnicity.to_a.reject(&:blank?),
          indian_tribe_member: indian_tribe_member,
          tribal_id: tribal_id,
          tribal_state: tribal_state,
          tribal_name: tribal_name,
          tribe_codes: tribe_codes.to_a.reject(&:blank?),
          citizen_status: citizen_status,
          is_temporarily_out_of_state: is_temporarily_out_of_state,
          immigration_doc_statuses: immigration_doc_statuses.to_a.reject(&:blank?)
        } #.reject{|_k, val| val.nil?}

        # This will update both the relationship being passed through,
        # and the corresponding relative inverse relationship
        update_relationship_and_relative_relationship(relationship) if relationship

        if is_dependent == "true" && same_with_primary == "true"
          primary = application.primary_applicant
          attrs.merge!(no_dc_address: primary.no_dc_address, is_homeless: primary.is_homeless?, is_temporarily_out_of_state: primary.is_temporarily_out_of_state?)
        end

        attrs.merge!(vlp_parameters)
        attrs.merge({
                      addresses: nested_parameters[:addresses_attributes].values,
                      phones: nested_parameters[:phones_attributes]&.values || [],
                      emails: nested_parameters[:emails_attributes]&.values || []
                    })
      end

      def vlp_parameters
        [:vlp_subject, :alien_number, :i94_number, :visa_number, :passport_number, :sevis_id,
         :naturalization_number, :receipt_number, :citizenship_number, :card_number,
         :country_of_citizenship, :expiration_date, :issuing_country, :status, :vlp_description].inject({}) do |attrs, attribute|
          attrs[attribute] = self.send(attribute) if self.send(attribute).present?
          attrs
        end
      end

      def nested_parameters
        @nested_parameters || build_nested_parameters
      end

      def build_nested_parameters
        address_params = addresses_attributes.reject{|_key, value| value[:address_1].blank? && value[:city].blank? && value[:state].blank? && value[:zip].blank?}

        # Removes mailing address if it is marked for destroy from the params
        address_params = address_params.reject { |_key, address| destroy_mailing_address?(address) }

        address_params = primary_applicant_address_attributes if is_dependent == "true" && same_with_primary == "true"

        params = {addresses_attributes: address_params}
        params.merge(phones_attributes: phones_attributes.reject{|_key, value| value[:full_phone_number].blank?}) if phones_attributes.present?
        params.merge(emails_attributes: emails_attributes.reject{|_key, value| value[:address].blank?}) if emails_attributes.present?
        params
      end

      def primary_applicant_address_attributes
        primary = application.primary_applicant
        if (home_address = primary.addresses.in(kind: 'home').first)
          address_params = {
            0 => home_address.attributes.slice('address_1', 'address_2', 'address_3', 'county', 'country_name', 'kind', 'city', 'state', 'zip')
          }
        end

        address_params || {}
      end

      def age_on(date)
        age = date.year - dob.year
        if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
          age - 1
        else
          age
        end
      end

      def relationship_validation
        return self.errors.add(:base, "select Relationship Type") if !applicant&.is_primary_applicant && relationship.blank?
        primary_relations = application.relationships.where(applicant_id: application.primary_applicant.id, :kind.in => ['spouse', 'life_partner'])
        if applicant
          other_spouses = primary_relations.reject{ |r| r.relative_id == applicant.id }
          self.errors.add(:base, "can not have multiple spouse or life partner") if ['spouse', 'life_partner'].include?(relationship) && !other_spouses.empty?
        elsif ['spouse', 'life_partner'].include?(relationship) && primary_relations.count >= 1
          self.errors.add(:base, "can not have multiple spouse or life partner")
        end
      end

      def check_same_ssn
        return if ssn.blank?
        return if applicant && applicant.ssn == ssn
        encrypted_ssn = FinancialAssistance::Applicant.encrypt_ssn(ssn)
        same_ssn = ::FinancialAssistance::Application.where("applicants.encrypted_ssn" => encrypted_ssn)
        self.errors.add(:base, "ssn is already taken") if same_ssn.present?
      end

    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize