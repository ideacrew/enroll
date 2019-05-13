require File.join(Rails.root, "lib/mongoid_migration_task")

class MaNfpReports < MongoidMigrationTask
  def migrate
    file_name = "#{Rails.root}/ma_nfp_report.csv"
    start_on = Date.strptime(ENV['start_on'],'%m/%d/%Y')
    field_names  = %w(
              Employer_Legal_Name
              Employer_FEIN
              2018_Plan_year_effective_date
              2018_Plan_year_status
              2019_Plan_year_effective_date
              2019_Plan_year_status
              EE_First_name
              EE_Last_name
              Roster_status
              EE_hbx_id
              2018_enrollment
              2018_coverage_kind
              2018_plan
              2018_effective_on
              2018_status
              2019_enrollment
              2019_coverage_kind
              2019_plan
              2019_effective_on
              2019_status
            )

    system("rm -rf #{Rails.root}/ma_nfp_report.csv")

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min'=>start_on).each do |ben_spon|
      ben_spon.benefit_applications.each do |bene_app|

        if bene_app.effective_period.min == start_on && bene_app.is_renewing?
          bene_app_2018 = ben_spon.benefit_applications.where(:"effective_period.min".lt=>start_on, aasm_state: :active).first
          ben_spon.census_employees.active.each do |census|
            if census.employee_role.present?
                family = census.employee_role.person.primary_family
              bene_app_2018 = ben_spon.benefit_applications.where(:"effective_period.min".lt =>start_on, aasm_state: :active).first
              packages_2018 = bene_app_2018.present? ? bene_app_2018.benefit_packages.map(&:id) : []

              package_ids = packages_2018 + bene_app.benefit_packages.map(&:id)

              enrollment = family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in=>package_ids, :aasm_state.nin=>["shopping","coverage_canceled","coverage_expired","coverage_terminated"])
            end
            next unless enrollment
            ["health", "dental"].each do |kind|
              enrollment_2018 = enrollment.where(coverage_kind: kind, :"effective_on".lt=> start_on).first
              enrollment_2019 = enrollment.where(coverage_kind: kind, :effective_on=> start_on).first
              next unless enrollment_2019
              
              csv << [ben_spon.profile.legal_name,
                      ben_spon.profile.fein,
                      bene_app_2018.try(:effective_period).try(:min),
                      bene_app_2018.try(:aasm_state),
                      bene_app.effective_period.min,
                      "renewing_#{bene_app.aasm_state}",
                      census.first_name,
                      census.last_name,
                      census.aasm_state,
                      census.try(:employee_role).try(:person).try(:hbx_id),
                      enrollment_2018.try(:hbx_id),
                      enrollment_2018.try(:coverage_kind),
                      enrollment_2018.try(:product).try(:hios_id),
                      enrollment_2018.try(:effective_on),
                      enrollment_2018.try(:aasm_state),
                      enrollment_2019.try(:hbx_id),
                      enrollment_2018.try(:coverage_kind),
                      enrollment_2019.try(:product).try(:hios_id),
                      enrollment_2019.try(:effective_on),
                      enrollment_2019.try(:aasm_state),
                      ]
             end
            end
          end
        end
      end
    end
  end
end


