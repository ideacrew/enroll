# updating the aasm_state of this employer to enrolled.
namespace :update do
  task :employer_status_to_enrolled => :environment do
    organization = Organization.where(fein:ENV['fein']).first
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