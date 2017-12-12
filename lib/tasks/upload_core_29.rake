# require File.join(Rails.root, "app", "data_migrations", "update_tax_households")
require 'csv'
namespace :migrations do
  # desc "upload core 29"
  task :upload_core_29 => :environment do
    desc "Load the people data"

    CSV.foreach("#{Rails.root}/hbx_report/families_with_application.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |row|
      binding.pry
      f_id = row.to_hash[:family_id]
      app = Family.find(f_id).applications.create(row.to_hash)
      app.update_attributes(aasm_state: "draft")

      CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |row2|
        binding.pry
        if Family.find(row.to_hash[:family_id]).family_members.first.id.to_s.gsub(/\n/, "").strip==row2.to_hash[:family_member_id]
          aplicant_id = FinancialAssistance::Application.find(app.id).applicants.create(row2.to_hash)
        end
      end
    end
    puts "uploaded from CSV"
  end
end



