# Running the task with arguments from command line
# Ex: rake notice:shop_employer_notice[5981e03960be9d05c900000b,initial_shop_application_approval]
namespace :notice do
  desc "Generate shop employer notices"
  task :shop_employer_notice, [:census_employee_id, :event_name] => :environment do |task, args|
    @census_employee_id = args[:census_employee_id].to_s
    @event_name = args[:event_name].to_s
    if @census_employee_id.present? && @event_name.present?
      ShopNoticesNotifierJob.perform_now(@census_employee_id, @event_name)
    else
      Rails.logger.error "shop_employer_notice: invalid arguments."
    end
  end
end
