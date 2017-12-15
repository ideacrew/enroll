require File.join(Rails.root, "lib/mongoid_migration_task")

class UploadFAA < MongoidMigrationTask
  def migrate
    CSV.foreach("#{Rails.root}/hbx_report/families_with_application.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |application|
      f_id = application.to_hash[:family_id]
      app = Family.find(f_id).applications.create(application.to_hash)
      app.update_attributes(workflow: {"current_step" => 2})
      CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |applicant|
        app_family_member = Family.find(f_id).family_members.where(id: applicant.to_hash[:family_member_id]).first
        app_family_member_id =app_family_member.id.to_s if app_family_member.present?
        # if Family.find(application.to_hash[:family_id]).family_members.first.id.to_s.gsub(/\n/, "").strip==row2.to_hash[:family_member_id]
        if app_family_member_id == applicant.to_hash[:family_member_id]
          applicant = FinancialAssistance::Application.find(app.id).applicants.create(applicant.to_hash)
          applicant.update_attributes(workflow: {"current_step" => 1})
          applicant.save!

          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_income.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |income|
            if income.present?
              applicant.incomes.create(income.to_hash)
              # applicant.incomes.update_attributes(workflow: {})
            end
          end

          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_benefit.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |benefit|
            applicant.benefits.create(benefit.to_hash) if benefit.present?
          end

          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_deduction.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |deduction|
            if deduction.present?
              applicant.deductions.create(deduction.to_hash)
              # applicant.deductions.update_attributes(workflow: {})
            end
          end
        end
      end
    end
    puts "uploaded from CSV"
  end
end