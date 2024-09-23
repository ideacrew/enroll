# frozen_string_literal: true

# This script finds and updates the permissions for the given names.
# This script expectes the following ENV variables to be set:
#   - CLIENT: the client name
#   - NAMES: the names of the permissions to be updated
#   - FIELD_NAME: the field name to be updated
#   - FIELD_VALUE: the value to be updated

# Command to trigger the script:
#   CLIENT=me NAMES='super_admin, hbx_staff, hbx_csr_supervisor, hbx_csr_tier1, hbx_csr_tier2' FIELD_NAME='can_change_username_and_email' FIELD_VALUE='true' bundle exec rails runner script/update_permissions.rb

names = ENV['NAMES'].split(',').map(&:strip)

field_value = if ENV['FIELD_VALUE'] == 'true'
  true
elsif ENV['FIELD_VALUE'] == 'false'
  false
else
  p 'Invalid value for FIELD_VALUE. It should be either true or false. EXITING...'
  exit
end

CSV.open("#{Rails.root}/permissions_update_report.csv", 'w', force_quotes: true) do |csv|
  csv << ['Permission Name', 'Update Result']

  result = ::Operations::Permissions::FindAndUpdate.new.call(
    { names: names, field_name: ENV['FIELD_NAME'], field_value: field_value }
  )

  if result.success?
    result.success.each do |name, message|
      csv << [name, message]
    end
  else
    csv << ['Errored', result.failure]
  end
end

p 'Permissions update report generated successfully with the name permissions_update_report.csv at the root of the project.'
p '****** Password protect the file and attach it to the PIVOTAL ticket. ******'
