# Running the task with arguments from command line
# Ex: rake notice:shop_employer_notice["541634423",initial_shop_application_approval]

namespace :notice do
  desc "Generate shop employer notices"
  task :shop_employer_notice, [:fein, :event_name, :state] => :environment do |task, args|
    @fein = args[:fein].to_s
    @event_name = args[:event_name].to_s
    @options = args[:state].to_s
    @state_options = {:state => @options}
    if @fein.present? && @event_name.present?
      organization = BenefitSponsors::Organizations::Organization.where(fein: @fein).first
      employer_profile = organization.employer_profile
      benefit_application = organization.active_benefit_sponsorship.benefit_applications.where(:aasm_state.in => ["approved", "enrollment_open", "enrollment_eligible"]).first
      service = BenefitSponsors::Services::NoticeService.new
      service.deliver(recipient: employer_profile, event_object: benefit_application, notice_event: @event_name, notice_params: @state_options)
    else
      Rails.logger.error "shop_employer_notice: invalid arguments." unless Rails.env.test?
    end
  end
end
