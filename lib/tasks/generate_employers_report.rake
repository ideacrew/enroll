# RAILS_ENV=production bundle exec rake generate_report:employers py_start_on="2019/01/01" py_end_on="2019/12/31" hios_id="86052"

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
    file_name = "#{Rails.root}/hbx_report/emp_report_with_reference_plan#{hios_id}_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

    CSV.open(file_name, "w", force_quotes: false) do |csv|
      csv << field_names

      Organization.plan_year_start_on_or_after(start_on).each do |organization|

        puts "Generating report" unless Rails.env.test?
        profile = organization.employer_profile

        profile.plan_years.by_date_range(start_on, end_on).each do |plan_year|

          plan_year.benefit_groups.each do |bg|
            reference_plan = bg.reference_plan

            next unless bg.reference_plan.present?

            if reference_plan.hios_id =~ /#{hios_id}/
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

              puts "completed" unless Rails.env.test?
            end
          end
        end
      end
    end
  end
end
