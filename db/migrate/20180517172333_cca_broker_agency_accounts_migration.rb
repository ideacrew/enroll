class CcaBrokerAgencyAccountsMigration < Mongoid::Migration
  def self.up
    new_organizations = BenefitSponsors::Organizations::Organization

    new_organizations.employer_profiles.each do |organization|

      old_ep_org = Organization.all_employer_profiles.where(hbx_id: organization.hbx_id)
      old_ep = old_ep_org.first.employer_profile
      old_ep_bk_agency_accs = find_broker_agency_accounts(old_ep)
      benefit_sponsorships = organization.benefit_sponsorships

      # This is used when there is only one benefit sponsorship
      if old_ep_org.present?
        if benefit_sponsorships.count == 1
          old_ep_bk_agency_accs.each do |old_ep_bk_agency_acc|
            old_bk_org = find_old_bk_org(old_inactive_broker_agency_account)
            create_broker_agency_account(new_organizations, old_bk_org, old_ep_bk_agency_acc, benefit_sponsorships.first)
            old_ep_bk_agency_acc.save!
          end

        end
      end

      # This is used when there is more than one benefit sponsorship
      if benefit_sponsorships.count > 1
        #this is to migrate active borker agency accounts to active benefit sponsors
        say_with_time("time to migrate active broker agency accounts") do
          active_benefit_sponsorship = non_ended_benefit_sponsorship(organization)
          benefit_sponsorship_start_date = active_benefit_sponsorship.effective_start_on

          #active broker_agency_accounts for respective organization
          old_ep_active_broker_agency_account = find_broker_agency_account(old_ep, true)
          hire_date = old_ep_active_broker_agency_account.start_on.to_date

          #Migrate employer_profiles, broker_agency and benefit sponsorships before migrating broker agency accounts
          if active_benefit_sponsorship.present? && old_ep_active_broker_agency_account.present? && benefit_sponsorship_start_date >= hire_date

            #querying old organization with old_broker_agency_account to get new broker org with HBX_id
            old_bk_org = find_old_bk_org(old_ep_active_broker_agency_account)

            create_broker_agency_account(new_organizations, old_bk_org, old_ep_active_broker_agency_account, active_benefit_sponsorship)
            active_benefit_sponsorship.save!
            organization.save!
          end
        end

        #this is to migrate inactive borker agency accounts to inactive benefit sponsorships
        say_with_time("time to migrate inactive broker agency accounts") do
          benefit_sponsorships = all_benefit_sponsorships(organization)

          #collecting broker_agency_accounts for respective organization
          old_ep_inactive_broker_agency_accounts = find_broker_agency_account(old_ep, false)


          old_ep_inactive_broker_agency_accounts.each do |old_inactive_broker_agency_account|
            hire_date = old_inactive_broker_agency_account.start_on.to_date

            if inactive_benefit_sponsorships.present?
              inactive_benefit_sponsorship = inactive_benefit_sponsorships.where(:"effective_begin_on".gte => hire_date).and(:"effective_begin_on".lte => hire_date).first

              #querying old organization with old_broker_agency_account to get new broker org with HBX_id
              old_bk_org = find_old_bk_org(old_inactive_broker_agency_account)

              create_broker_agency_account(new_organizations, old_bk_org, old_inactive_broker_agency_account, inactive_benefit_sponsorship)
              inactive_benefit_sponsorship.save!
            end
          end

          organization.save!
        end
      end
    end
  end

  def self.down
  end

  private

  def self.find_broker_agency_account(old_ep, active_status)
    old_ep.broker_agency_accounts.unscoped.where(is_active: active_status)
  end

  def self.find_broker_agency_accounts(old_ep)
    old_ep.broker_agency_accounts.unscoped
  end

  def self.non_ended_benefit_sponsorship organization
    organization.benefit_sponsorships.where(effective_end_on: nil).first
  end

  def self.ended_benefit_sponsorships organization
    organization.benefit_sponsorships.where(effective_end_on: {'$ne' => nil})
  end

  def self.find_old_bk_org old_broker_agency_account
    Organization.has_broker_agency_profile.where(:"broker_agency_profile._id" => BSON::ObjectId(old_broker_agency_account.broker_agency_profile_id))
  end

  def self.create_broker_agency_account(new_organizations, old_bk_org, old_broker_agency_account, benefit_sponsorship)
    new_org = new_organizations.where(hbx_id: old_bk_org.first.hbx_id)

    json_data = old_broker_agency_account.to_json(:except => [:_id, :broker_agency_profile_id, :writing_agent_id])
    broker_agency_account_params = JSON.parse(json_data)
    broker_agency_profile_id = new_org.first.broker_agency_profile.id
    person = Person.where(:"broker_role.benefit_sponsors_broker_agency_profile_id" => broker_agency_profile_id)
    broker_role_id = person.first.broker_role.id

    #creating broker_agency account in new model
    new_broker_agency_account = benefit_sponsorship.broker_agency_accounts.new(broker_agency_account_params)
    new_broker_agency_account.writing_agent_id = broker_role_id if old_broker_agency_account.writing_agent_id.present?
    new_broker_agency_account.benefit_sponsors_broker_agency_profile_id = new_org.first.broker_agency_profile.id
    new_broker_agency_account.save!
  end
end