# Run the following - bundle exec rake migrations:generate_notices
# To run rake task: RAILS_ENV=production bundle exec rake notices:triggger_shop_notices recipient_ids="522111704, 300266649, 260077227" event="initial_employer_ineligibility_notice"

require 'csv'

namespace :notices do
  desc "Trigger SHOP notices manually"
  task :triggger_shop_notices => :environment do

    begin
      event = ENV['event']
      feins = ENV['recipient_ids'].split(',').map(&:lstrip)

      feins.each do |fein|
        organization = Organization.where(fein: fein).first
        if organization.present?
          ShopNoticesNotifierJob.perform_later(organization.employer_profile.id.to_s, event)
          puts "Notice of #{event} delivered to #{organization.legal_name}" unless Rails.env.test?
        end
      end
    rescue Exception => e
      Rails.logger.error { "Unable to deliver #{event} notice for #{organization.legal_name} due to #{e}" }
    end
  end
end

# can extend code to trigger for employee, broker, GA notices