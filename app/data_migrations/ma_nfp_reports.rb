# require File.join(Rails.root, "lib/mongoid_migration_task")

class MaNfpReports

  def initialize(start_on)
    detailed_report(start_on)
    assign_packages(start_on)
    non_detailed_report(start_on)
  end

  def detailed_report(start_on)
    file_name = "#{Rails.root}/ma_nfp_detailed_report.csv"
    # start_on = Date.strptime(ENV['start_on'],'%m/%d/%Y')
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

    system("rm -rf #{file_name}")

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
              enrollment = family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in=>package_ids, :aasm_state.nin=>["shopping","coverage_canceled","coverage_expired"])
            end
            next unless enrollment
            ["health", "dental"].each do |kind|
              enrollment_2018 = enrollment.where(coverage_kind: kind, :"effective_on".lt=> start_on).first
              enrollment_2019 = enrollment.where(coverage_kind: kind, :effective_on=> start_on).first
              next unless enrollment_2018 || enrollment_2019
              
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



def assign_packages(start_on)
  CSV.open("#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
    csv << ["Sponsor fein", "Sponsor legal_name", "Census_Employee", "ce id"]
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min'=>start_on).each do |ben_spon|
        ben_spon.benefit_applications.each do |bene_app|
          if bene_app.effective_period.min == start_on && bene_app.is_renewing?
            bene_app_2018 = ben_spon.benefit_applications.where(:"effective_period.min".lt=>start_on, aasm_state: :active).first
            ben_spon.census_employees.active.each do |census|
              if census.employee_role.present?
                if census.benefit_group_assignments.where(:benefit_package_id.in => bene_app.benefit_packages.map(&:id)).blank?
                  unless census.aasm_state == "employment_terminated" || census.aasm_state == "rehired" ||  census.aasm_state == "cobra_terminated"
                data = [ben_spon.fein, ben_spon.legal_name, census.full_name, census.id]  
                csv << data
                end
              end
            end
            puts "#{ben_spon.fein} has errors #{ben_spon.errors}" if ben_spon.errors.present? unless Rails.env.test?
          end
        end
      end
    end
    puts "Unnasigned packages file created" unless Rails.env.test?
  end
end

def non_detailed_report(start_on)
  file_name = "#{Rails.root}/ma_nfp_non_detailed_report.csv"
  # start_on = Date.strptime(ENV['start_on'],'%m/%d/%Y')
  field_names  = [
    "Employer_Legal_Name",
    "Employer_FEIN",
    "Renewal State",
    "#{start_on.prev_year.year} Active Enrollments",
    "#{start_on.prev_year.year} Passive Renewal Enrollments"
  ]
  system("rm -rf #{file_name}")

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min'=>start_on).each do |ben_spon|
      ben_spon.benefit_applications.each do |bene_app|
        if bene_app.effective_period.min == start_on && bene_app.is_renewing?
          data =  [ben_spon.legal_name, ben_spon.fein, ben_spon.renewal_benefit_application.aasm_state.to_s.camelcase]
          next if ben_spon.renewal_benefit_application.blank?
          active_bg_ids = ben_spon.current_benefit_application.benefit_packages.pluck(:id)
          families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:sponsored_benefit_package_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
            }})
          if ben_spon.renewal_benefit_application.present?
            if ben_spon.renewal_benefit_application.aasm_state.in?([:enrollment_open, :enrollment_extended, :enrollment_closed])
              renewal_bg_ids = ben_spon.renewal_benefit_application.benefit_packages.pluck(:id)
            end
          end

          active_enrollment_count = 0
          renewal_enrollment_count = 0
          families.each do |family|
                enrollments = family.active_household.hbx_enrollments.where({
                  :sponsored_benefit_package_id.in => active_bg_ids,
                  :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
                })
                %w(health dental).each do |coverage_kind|
                  if enrollments.where(:coverage_kind => coverage_kind).present?
                    active_enrollment_count += 1
                  end
                end

                if renewal_bg_ids.present?
                  renewal_enrollments = family.active_household.hbx_enrollments.where({
                    :sponsored_benefit_package_id.in => renewal_bg_ids,
                    :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
                  })

                  %w(health dental).each do |coverage_kind|
                    if renewal_enrollments.where(:coverage_kind => coverage_kind).present?
                      renewal_enrollment_count += 1
                    end
                  end
                end
              end
          data += [active_enrollment_count, renewal_enrollment_count]
          csv << data
        end
      end
    end
  end
end  

start_on = Date.new(2019,6,1)
reports = MaNfpReports.new(Date.new(2019,6,1))
# reports.rub(start_on)