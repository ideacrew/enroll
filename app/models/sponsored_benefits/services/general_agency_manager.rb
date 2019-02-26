module SponsoredBenefits
  module Services
    class GeneralAgencyManager
      include Acapi::Notifiers

      attr_accessor :form
     
      def initialize(form)
        @form = form
      end

      def assign_general_agency(start_on: TimeKeeper.datetime_of_record)
        form.plan_design_organization_ids.each do |id|
          unless fire_previous_general_agency(id)
            map_failed_assignment_on_form(id)
            next
          end
          create_general_agency_account(id, broker_agency_profile.primary_broker_role.id, start_on)
        end
      end

      def fire_general_agency(ids=form.plan_design_organization_ids)
        ids.each do |id|
          plan_design_organization(id).general_agency_accounts.active.each do |account|
            account.terminate!
            # toDo - check DC notice Engine refactor
            # notify_general_agent_terminated
            # self.trigger_notices("general_agency_terminated")
          end
        end
      end

      def create_general_agency_account(id, broker_role_id, start_on=TimeKeeper.datetime_of_record, general_agency_profile_id=form.general_agency_profile_id, broker_agency_profile_id=form.broker_agency_profile_id)
        plan_design_organization(id).general_agency_accounts.build(
          start_on: start_on,
          general_agency_profile_id: general_agency_profile_id,
          broker_agency_profile_id: broker_agency_profile_id,
          broker_role_id: broker_role_id
        ).tap do |account|
          if account.save
            # toDo - check DC notice Engine refactor
            # send_general_agency_assign_msg(general_agency_profile, employer_profile, 'Hire')
            # general_agency_profile.general_agency_hired_notice(employer_profile) #GA notice when broker Assign a GA to employers
          else
            map_failed_assignment_on_form(id) if form.present?
          end
        end
      end

      def set_default_general_agency
        prev_default_ga_id = current_default_ga.id if current_default_ga
        broker_agency_profile.default_general_agency_profile = general_agency_profile
        broker_agency_profile.save!
        notify("acapi.info.events.broker.default_ga_changed", {:broker_id => broker_agency_profile.primary_broker_role.hbx_id, :pre_default_ga_id => prev_default_ga_id})
      end

      def clear_default_general_agency
        prev_default_ga_id = current_default_ga.id if current_default_ga
        broker_agency_profile.default_general_agency_profile = nil
        broker_agency_profile.save!
        notify("acapi.info.events.broker.default_ga_changed", {:broker_id => broker_agency_profile.primary_broker_role.hbx_id, :pre_default_ga_id => prev_default_ga_id})
      end

      def fire_previous_general_agency(id)
        fire_general_agency([id])
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

      def broker_agency_profile(id=form.broker_agency_profile_id)
        return @broker_agency_profile if defined? @broker_agency_profile
        @broker_agency_profile = ::BrokerAgencyProfile.find(id) || BenefitSponsors::Organizations::Profile.find(id)
      end

      def general_agency_profile(id=form.general_agency_profile_id)
        return @general_agency_profile if defined? @general_agency_profile
        @general_agency_profile = ::GeneralAgencyProfile.find(id) || BenefitSponsors::Organizations::Profile.find(id)
      end

      def current_default_ga
        broker_agency_profile.default_general_agency_profile
      end
    end
  end
end
