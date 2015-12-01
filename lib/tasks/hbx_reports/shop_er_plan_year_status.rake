namespace :reports do
  namespace :shop do

    desc "Employer plan year application status by effective date"
    task :er_plan_year_status => :environment do
      effective_date = Date.new(2016,1,1)
      organizations = Organization.all_employers_by_plan_year_start_on(effective_date)
      puts "fein, legal_name, dba, employer_status, plan_year_start_on, plan_year_status, benefit_package, plan_option, ref_plan_year, ref_plan_name, ref_plan_hios_id"

      organizations.each do |organization|
        organization.employer_profile.plan_years.each do |plan_year|
          plan_year.benefit_groups.each do |benefit_group|
            # hbx_id              = benefit_group.plan_year.employer_profile.hbx_id
            fein                = benefit_group.plan_year.employer_profile.organization.fein
            legal_name          = benefit_group.plan_year.employer_profile.organization.legal_name.gsub(',','')
            dba                 = benefit_group.plan_year.employer_profile.organization.dba.gsub(',','')
            employer_state      = benefit_group.plan_year.employer_profile.aasm_state
            plan_year_start_on  = benefit_group.plan_year.start_on
            plan_year_state     = benefit_group.plan_year.aasm_state
            benefit_package     = benefit_group.title.gsub(',','')
            plan_option         = benefit_group.plan_option_kind
            reference_plan_name = benefit_group.reference_plan.name.gsub(',','')
            reference_plan_hios_id = benefit_group.reference_plan.hios_id
            reference_plan_active_year = benefit_group.reference_plan.active_year

            puts "#{fein}, #{legal_name}, #{dba}, #{employer_state}, #{plan_year_start_on}, #{plan_year_state}, #{benefit_package}, #{plan_option}, #{reference_plan_active_year}, #{reference_plan_name}, #{reference_plan_hios_id}"
          end
        end
      end

    end
  end
end