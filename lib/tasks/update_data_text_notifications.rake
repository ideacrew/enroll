# frozen_string_literal: true

require "#{Rails.root}/components/financial_assistance/app/helpers/financial_assistance/jobs_helper"

namespace :update_data do
  include FinancialAssistance::JobsHelper

  desc "Updates people with only text notifications to text and mail"
  task text_only_notification_to_text_and_paper: :environment do
    start_time = process_start_time
    meta = Person.only_text_notifications.update_all(:'consumer_role.contact_method' => ConsumerRole::CONTACT_METHOD_MAPPING[["Mail", "Text"]])
    end_time = process_end_time_formatted(start_time)
    puts "-------------------"
    puts "Updated #{meta.first['nModified']} people with only text notifications to text and mail"
    puts "Time taken to update: #{end_time}"
  end

end
