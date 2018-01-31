# This rake task will trigger notice to employers by taking either hbx_ids or employer_ids or feins and event_name
# Running the task with arguments from command line
# Ex: rake notice:shop_employer_notice_event hbx_ids="1231 121 1567" feins="42112 12123 123123" employer_ids = "123123 12312312 123123123" event="specific_event"
namespace :notice do
  desc "Generate shop employer notices"
  task :shop_employer_notice_event => :environment do |task, args|
    @employer_ids = ENV['employer_ids'].try(:split, " ")
    @hbx_ids = ENV['hbx_ids'].try(:split, " ")
    @feins = ENV['feins'].try(:split, " ")
    @event_name = ENV['event']
    if @event_name
      case
        when @employer_ids
          @employer_ids.each do | employer_id |
            employer_profile_id = EmployerProfile.find(employer_id).id.to_s
            ShopNoticesNotifierJob.perform_later(employer_profile_id, @event_name) if employer_profile_id
          end
        when @hbx_ids
          @hbx_ids.each do |hbx_id|
            employer_profile_id = Organization.where(hbx_id: hbx_id).first.employer_profile.id.to_s
            ShopNoticesNotifierJob.perform_later(employer_profile_id, @event_name) if employer_profile_id
            puts "Notice Triggered Successfully"
          end
        when @feins
          @feins.each do |fein_id|
            employer_profile_id = Organization.where(fein: fein_id).first.employer_profile.id.to_s
            ShopNoticesNotifierJob.perform_later(employer_profile_id, @event_name) if employer_profile_id
            puts "Notice Triggered Successfully"
          end
        else
          puts "Please provide either hbx_id or feins as arguments"
      end
    else
       puts "Please specify the type of event name which we want to trigger"
    end
  end
end
