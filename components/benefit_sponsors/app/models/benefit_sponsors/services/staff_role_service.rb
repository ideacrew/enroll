module BenefitSponsors
  module Services
    class StaffRoleService

      attr_accessor :profile_id, :profile_type, :person

      def initialize(attrs={})
        @attrs = attrs
        @profile_id = attrs[:profile_id]
        @profile_type = attrs[:profile_type]
      end

      def find_profile(form)
        organization = BenefitSponsors::Organizations::Organization.where("profiles._id" => BSON::ObjectId.from_string(form[:profile_id])).first
        if form[:is_broker_agency_staff_profile?]
          organization.broker_agency_profile if organization.present?
        else
          organization.employer_profile if organization.present?
        end
      end

      def add_profile_representative!(form)
        profile = find_profile(form)
        if form[:is_broker_agency_staff_profile?]
          Person.add_broker_agency_staff_role(form[:first_name], form[:last_name], form[:dob], form[:email] , profile)
        elsif form.profile_type == "broker_agency_staff"
          match_or_create_person(form)
          persist_broker_agency_staff_role!(profile)
        else
          Person.add_employer_staff_role(form[:first_name], form[:last_name], form[:dob], form[:email] , profile)
        end
      end

      def deactivate_profile_representative!(form)
        profile = find_profile(form)
        person_ids = form[:is_broker_agency_staff_profile?] ? profile.staff_for_broker.map(&:id) : Person.staff_for_employer(profile).map(&:id)
        if person_ids.count == 1 && person_ids.first.to_s == form[:person_id]
          return false, 'Please add another staff role before deleting this role'
        else
          form[:is_broker_agency_staff_profile?] ? Person.deactivate_broker_agency_staff_role(form[:person_id], form[:profile_id]) : Person.deactivate_employer_staff_role(form[:person_id], form[:profile_id])
        end
      end

      def approve_profile_representative!(form)
        person = Person.find(form[:person_id])

        if (form[:is_broker_agency_staff_profile?])
          role = person.broker_agency_staff_roles.detect{|role| role.agency_pending? && role.benefit_sponsors_broker_agency_profile_id.to_s == form[:profile_id]}
        else
          role = person.employer_staff_roles.detect{|role| role.is_applicant? && role.benefit_sponsor_employer_profile_id.to_s == form[:profile_id]}
        end

        if role && role.approve && role.save!
          return true, 'Role is approved'
        else
          return false, 'Please contact HBX Admin to report this error'
        end

      end

      def match_or_create_person(form)
        matched_people = get_matched_people(form)

        if matched_people.count > 1
          errors.add(:staff_role, "too many people match the criteria provided for your identity.  Please contact HBX.")
          return false
        end
        if matched_people.count == 1
          mp = matched_people.first
          self.person = mp
        else
          self.person = build_person(form)
        end

        #add_person_contact_info
        person.save!

      end

      def get_matched_people(form)
        if self.profile_type == "broker_agency_staff"
          Person.where(
              first_name: regex_for(form[:first_name]),
              last_name: regex_for(form[:last_name]),
              dob: self[:dob]
          )
        else
          Person.where(
              first_name: regex_for(form[:first_name]),
              last_name: regex_for(form[:last_name])
          )
        end
      end

      def persist_broker_agency_staff_role!(profile)
        exisiting_brokers_with_same_profile =  person.broker_agency_staff_roles.select{|role| role if role.benefit_sponsors_broker_agency_profile_id == profile.id }
        if exisiting_brokers_with_same_profile.present?

          return false,  "You are already associated with the Broker Agency"
        else
          person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new({
                                                                              broker_agency_profile: profile
                                                                          })
          person.save!
          return true, person
        end
      end


      def add_person_contact_info
        if is_broker_profile?
          person.add_work_email(email)
        elsif is_employer_profile?
          person.contact_info(email, area_code, number, extension) if email
        end
      end

      def build_person(form)
        Person.new({
                       :first_name => form[:first_name].strip,
                       :last_name => form[:last_name].strip,
                       :dob => form[:dob]
                   })
      end

      def regex_for(str)
        clean_string = ::Regexp.escape(str.strip)
        /^#{clean_string}$/i
      end

    end
  end
end
