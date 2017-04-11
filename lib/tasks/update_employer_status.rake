# Rake taks used to update the aasm_state of the employer to enrolled.
# To run rake task: RAILS_ENV=production bundle exec rake update:employer_status_to_enrolled fein=987654321
namespace :update do
  task :employer_status_to_enrolled => :environment do
    organization = Organization.where(fein:ENV['fein'])
    empr = organization.last.employer_profile
    puts "*"*80
    puts "found employer : #{empr.legal_name} "
    empr.aasm_state = "enrolled"
    if empr.valid?
      empr.save
      puts "successfully updated the aasm_state of #{empr.legal_name} to #{empr.aasm_state}"
    end
    puts "*"*80
  end
end
