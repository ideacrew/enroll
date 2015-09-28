require 'csv'

namespace :import_curam do

  desc "Import users from Curam"
  task curam_users: :environment do
    counter = 0
    filepath = File.join(Rails.root, 'db', 'seedfiles', 'curam_userlist.csv')
    CSV.foreach(filepath) do |row|
      username, firstname, lastname, ssn, dob = row
      user = CuramUser.create(username:username, first_name:firstname, last_name:lastname, ssn:ssn, dob: dob)
      puts "#{ssn} - #{user.errors.full_messages.join(",")}" if user.errors.any?
      counter += 1 if user.persisted?
    end
    puts "Imported #{counter} users."
  end
end
