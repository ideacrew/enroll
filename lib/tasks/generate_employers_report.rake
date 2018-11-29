#employers rake task
# RAILS_ENV=production bundle exec rake generate_report:employers py_start_on="2019/01/01" py_end_on="2019/12/31" hios_id="86052"

#enrollments rake task
# RAILS_ENV=production bundle exec rake generate_report:enrollments py_start_on="2019/01/01" py_end_on="2019/12/31" hios_id="86052"

namespace :generate_report do
  desc "Report of employers having plan with the given hios_id and plan year dates"
  task :employers => :environment do

    start_on = ENV["py_start_on"].to_date
    end_on = ENV["py_end_on"].to_date
    hios_id = ENV["hios_id"].first(5).to_i

    field_names = %w(
                      HBX_ID
                      FEIN
                      LEGAL_NAME
                      PLAN_YEAR_STATE
                      PLAN_YEAR_START_ON
                      PLAN_YEAR_END_ON
                      PLAN_HIOS_ID
                      PLAN_NAME
                      PLAN_MARKET
                      CARRIER_LEGAL_NAME
                    )

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/employer_with_plan_#{hios_id}_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

    CSV.open(file_name, "w", force_quotes: false) do |csv|
      csv << field_names
      puts "Generating employers report" unless Rails.env.test?
      Organization.plan_year_start_on_or_after(start_on).each do |organization|

        profile = organization.employer_profile

        profile.plan_years.by_date_range(start_on, end_on).each do |plan_year|

          plan_year.benefit_groups.each do |bg|
            reference_plan = bg.reference_plan

            expected_hios_ids = bg.elected_plans.map(&:hios_id).flatten.select {|e| /#{hios_id}/.match(e.to_s.first(5))}
            next unless bg.reference_plan.present?

            if reference_plan.hios_id =~ /#{hios_id}/ || expected_hios_ids.present?
              csv << [organization.hbx_id,
                      organization.fein,
                      organization.legal_name,
                      plan_year.aasm_state,
                      plan_year.start_on,
                      plan_year.end_on,
                      reference_plan.hios_id,
                      reference_plan.name,
                      reference_plan.market,
                      reference_plan.carrier_profile.legal_name]
            end
          end
        end
      end
      puts "completed" unless Rails.env.test?
    end
  end


  task :enrollments => :environment do
    start_on = ENV["py_start_on"].to_date
    end_on = ENV["py_end_on"].to_date
    hios_id = ENV["hios_id"].first(5).to_i

    field_names = %w(
                    PERSON_HBX_ID
                    PERSON_FIRST_NAME
                    PERSON_LAST_NAME
                    CE_ID
                    ENROLLMENT_HBX_ID
                    ENROLLMENT_EFFECTIVE_ON
                    ENROLLMENT_AASM_STATE
                    CE_PLAN_NAME
                    CE_PLAN_HIOS_ID
                    ORG_HBX_ID
                    ORG_FEIN
                    ORG_LEGAL_NAME
                    PLAN_YEAR_STATE
                    PLAN_YEAR_START_ON
                    PLAN_YEAR_END_ON
                    ORG_PLAN_HIOS_ID
                    ORG_PLAN_NAME
                    ORG_PLAN_MARKET
                    CARRIER_LEGAL_NAME
                    )

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/census_employee_with_plan_#{hios_id}_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

    CSV.open(file_name, "w", force_quotes: false) do |csv|
      csv << field_names
      puts "Generating census employees report" unless Rails.env.test?
      Organization.plan_year_start_on_or_after(start_on).each do |organization|
        profile = organization.employer_profile

        profile.plan_years.by_date_range(start_on, end_on).each do |plan_year|
          plan_year.benefit_groups.each do |bg|
            reference_plan = bg.reference_plan

            expected_hios_ids = bg.elected_plans.map(&:hios_id).flatten.select {|e| /#{hios_id}/.match(e.to_s.first(5))}

            if reference_plan.hios_id =~ /#{hios_id}/ || expected_hios_ids.present?
              profile.census_employees.each do |ce|
                person = ce.employee_role.person if ce.employee_role.present?
                ce.benefit_group_assignments.each do |bga|

                  enrollment = bga.hbx_enrollment
                  next unless enrollment.present?
                  next unless enrollment.plan.present?
                  plan = enrollment.plan
                  if plan && enrollment.plan.hios_id =~ /#{hios_id}/ && plan_year.start_on == enrollment.effective_on
                    csv << [person.present? ? person.hbx_id : "no person record",
                            ce.first_name,
                            ce.last_name,
                            ce.id,
                            enrollment.hbx_id,
                            enrollment.effective_on,
                            enrollment.aasm_state,
                            plan.name,
                            plan.hios_id,
                            organization.hbx_id,
                            organization.fein,
                            organization.legal_name,
                            plan_year.aasm_state,
                            plan_year.start_on,
                            plan_year.end_on,
                            reference_plan.hios_id,
                            reference_plan.name,
                            reference_plan.market,
                            reference_plan.carrier_profile.legal_name]
                  end
                end
              end
            end
          end
        end
      end
    end
    puts "completed" unless Rails.env.test?
  end
end