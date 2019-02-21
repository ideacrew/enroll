module SponsoredBenefits
  module Services
    class GeneralAgencyManager

      attr_accessor :broker_agency_profile, :general_agency_profile, :form
     
      def initialize(form)
        @form = form
      end

      def assign_general_agency(start_on: TimeKeeper.datetime_of_record)
        form.plan_design_organization_ids.each do |id|
          unless fire_previous_general_agency(id)
            map_failed_assignment_on_form(id)
            next
          end
 
          plan_design_organization(id).general_agency_accounts.build(
            start_on: start_on,
            general_agency_profile_id: form.general_agency_profile_id,
            broker_agency_profile_id: form.broker_agency_profile_id,
            broker_role_id: broker_agency_profile(form.broker_agency_profile_id).primary_broker_role.id
          ).tap do |account|
            if account.save
            else
              map_failed_assignment_on_form(id)
            end
          end
          # toDo - check DC notice Engine refactor
          # send_general_agency_assign_msg(general_agency_profile, employer_profile, 'Hire')
          # general_agency_profile.general_agency_hired_notice(employer_profile) #GA notice when broker Assign a GA to employers
        end
      end

      def fire_general_agency(id=form.plan_design_organization_id)
        plan_design_organization(id).general_agency_accounts.active.each do |account|
          account.terminate!
        end
        # toDo - check DC notice Engine refactor
        # notify_general_agent_terminated
        # self.trigger_notices("general_agency_terminated")
      end

      def fire_previous_general_agency(id)
        fire_general_agency(id)
      end

      def map_failed_assignment_on_form(id)
        form.errors.add("Assignment Failed for #{plan_design_organization(id).legal_name}")
      end

      def agencies
        ::GeneralAgencyProfile.all
      end

      def plan_design_organization(id)
        # Don't say return @plan design organization if defined?
        SponsoredBenefits::Organizations::PlanDesignOrganization.find(id)
      end

      def broker_agency_profile(id)
        return @profile if defined? @profile
        @profile = ::BrokerAgencyProfile.find(id) || BenefitSponsors::Organizations::Profile.find(id)
      end
    end
  end
end
