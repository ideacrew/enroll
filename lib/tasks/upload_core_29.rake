# require File.join(Rails.root, "app", "data_migrations", "update_tax_households")
require 'csv'
namespace :migrations do
  # desc "upload core 29"
  task :upload_core_29 => :environment do
    desc "Load the people data"

    CSV.foreach("#{Rails.root}/hbx_report/families_with_application.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |application|

      f_id = application.to_hash[:family_id]
      app = Family.find(f_id).applications.create(application.to_hash)
      app.update_attributes(aasm_state: "draft", renewal_base_year: 2017, workflow: {"current_step" => 2}) # move workflow to download

      CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |applicant|

        # if Family.find(application.to_hash[:family_id]).family_members.first.id.to_s.gsub(/\n/, "").strip==row2.to_hash[:family_member_id]
         if Family.find(f_id).family_members.find(applicant.to_hash[:family_member_id]).id.to_s == applicant.to_hash[:family_member_id]
          applicant = FinancialAssistance::Application.find(app.id).applicants.create(applicant.to_hash)
          applicant.update_attributes(workflow: {"current_step" => 1}) # move workflow to download
          applicant.save!

          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_income.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |income|
              aplicant.incomes.create(income.to_hash) if income.present?
          end

          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_benefit.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |benefit|
            aplicant.benefits.create(benefit.to_hash) if benefit.present?
          end

          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_deduction.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |deduction|
              aplicant.deductions.create(deduction.to_hash) if deduction.present?
          end
        end
      end
    end
    puts "uploaded from CSV"
  end
end




