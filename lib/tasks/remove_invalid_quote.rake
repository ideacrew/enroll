# This rake task is to remove invalid quote due to invalid contributions in bqt
# RAILS_ENV=production bundle exec rake bqt:remove_invalid_quote fein="12345" hbx_id="2341"
# RAILS_ENV=production bundle exec rake bqt:remove_invalid_quote hbx_id="2341" #when there is no fein

namespace :bqt do
  desc 'BQT - remove invalid plan design proposals due to invalid contributions'
  task :remove_invalid_quote => :environment do
    fein = ENV['fein'].to_s
    hbx_id = ENV['hbx_id']

    employer_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where(hbx_id: hbx_id).first

    if employer_organization.fein.to_s == fein
      plan_design_proposals = employer_organization.plan_design_proposals.select(&:invalid?)

      plan_design_proposals.each do |plan_design_proposal|
        benefit_sponsorship = plan_design_proposal.profile.benefit_sponsorships.first
        benefit_application = benefit_sponsorship.benefit_applications.first

        benefit_application.benefit_groups.each do |benefit_group|
          next if benefit_group.valid?

          error_messages = benefit_group.errors.full_messages
          benefit_group.delete

          puts "Successfully deleted invalid quote for hbx_id: #{hbx_id} with error:#{error_messages}"
        end
      end
    else
      puts 'Failed: Verify if provided fein and hbx_id matches with the account'
    end
  end
end
