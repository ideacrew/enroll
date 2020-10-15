# frozen_string_literal: true

# This rake tasks should be run to generate reports after plans loading.
# To generate all reports please use this rake command: RAILS_ENV=production bundle exec rake cca_plan_validation:reports active_date="2019-12-01" recipients="abc@example.gov,aba1@example.com"
namespace :cca_plan_validation do

  desc "reports generation after plan loading"
  task :reports => :environment do
    puts "Reports generation started" unless Rails.env.test?
    active_date = ENV['active_date'].to_date
    recipients = ENV['recipients']
    report = Services::PlanValidationReport.new(active_date)
    report.sheet1
    report.sheet2
    report.sheet3
    report.sheet4
    report.sheet5
    report.sheet6
    report.sheet7
    report.sheet8
    report.sheet9

    current_date = Date.today.strftime("%Y_%m_%d")
    file_name = "#{Rails.root}/CCA_PlanLoadValidation_Report_EA_#{current_date}.xlsx"
    report.generate_file(file_name)

    if Rails.env.production?
      pubber = Publishers::Legacy::PlanValidationReportPublisher.new
      pubber.publish URI.join("file://", file_name)
      UserMailer.generic_plan_validation_report_alert(recipients).deliver_now
    end
  end
end
