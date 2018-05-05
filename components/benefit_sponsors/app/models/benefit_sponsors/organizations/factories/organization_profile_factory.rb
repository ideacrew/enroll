module BenefitSponsors
  module Organizations
    class Factories::OrganizationProfileFactory

      include BenefitSponsors::Forms::ProfileInformation
      include BenefitSponsors::Forms::NpnField

      attr_accessor :legal_name, :dba, :entity_kind, :email, :person_id, :contact_method,
                    :npn, :market_kind, :languages_spoken, :working_hours, :accept_new_clients, :person, :home_page
      attr_reader :first_name, :last_name, :dob, :fein, :office_locations, :npn

      class PersonAlreadyMatched < StandardError; end
      class TooManyMatchingPeople < StandardError; end
      class OrganizationAlreadyMatched < StandardError; end

      def initialize(attrs)
        self.fein = attrs[:fein]
        self.first_name = attrs[:first_name]
        self.last_name = attrs[:last_name]
        self.dob = attrs[:dob]
        self.legal_name = attrs[:legal_name]
        self.dba = attrs[:dba]
        self.entity_kind = attrs[:entity_kind]
        self.email = attrs[:email]
        self.contact_method = attrs[:contact_method]
        self.person_id = attrs[:person_id]
        self.npn = attrs[:npn]
        self.market_kind = attrs[:market_kind]
        self.home_page = attrs[:home_page]
        self.languages_spoken = attrs[:languages_spoken]
        self.working_hours = attrs[:working_hours]
        self.accept_new_clients = attrs[:accept_new_clients]
        self.office_locations_attributes = attrs[:office_locations_attributes]
      end

      def init_organization
        # for now we're always doing General Organization
        class_name = GeneralOrganization || ExemptOrganization 

        class_name.new(
          :fein => fein,
          :legal_name => legal_name,
          :dba => dba,
          :entity_kind => entity_kind,
          :site => site
        )
      end

      def site
        BenefitSponsors::ApplicationController::current_site
      end

      def site_key
        site.site_key
      end

      def match_or_create_person(current_user)
        if !self.person_id.blank?
          self.person = Person.find(self.person_id)
          return
        end
        new_person =   Person.new({
          :first_name => first_name,
          :last_name => last_name,
          :dob => dob
        })
        if self.class.to_s.include?("BenefitSponsorFactory")
          matched_people = Person.where(
            first_name: regex_for(first_name),
            last_name: regex_for(last_name),
            dob: new_person.dob
            )
        else
          matched_people = Person.where(
            first_name: regex_for(first_name),
            last_name: regex_for(last_name),
            # TODO
            # dob: new_person.dob
          )
        end
        if matched_people.count > 1
          raise TooManyMatchingPeople.new
        end
        if matched_people.count == 1
          mp = matched_people.first
          if mp.user.present?
            if mp.user.id.to_s != current_user.id
              raise PersonAlreadyMatched.new
            end
          end
          self.person = mp
        else
          self.person = new_person
        end
      end

      def regex_for(str)
        #::Regexp.compile(::Regexp.escape(str.to_s))
        clean_string = ::Regexp.escape(str.strip)
        /^#{clean_string}$/i
      end
    end
  end
end
