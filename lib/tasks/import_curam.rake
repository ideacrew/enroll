require 'csv'
require 'date'

namespace :import_curam do

  desc "Import users from Curam"
  task curam_users: :environment do
    counter = 0
    filepath = File.join(Rails.root, 'db', 'seedfiles', 'curam_userlist.csv')
    CuramUser.where({}).delete
    CSV.foreach(filepath, headers: true) do |row|
      username, firstname, lastname, ssn, dob, *rest = row.fields
      dob_date = (dob.blank? ? nil : Date.strptime(dob, "%Y-%m-%d"))
      user = CuramUser.create(first_name:firstname, last_name:lastname, ssn:ssn, dob: dob_date, username: username)
      puts "#{ssn} - #{user.errors.full_messages.join(",")}" if user.errors.any?
      counter += 1 if user.persisted?
    end
    puts "Imported #{counter} users."
  end
end
