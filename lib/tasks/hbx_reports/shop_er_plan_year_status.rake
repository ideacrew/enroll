require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employer plan year application status by effective date"
    task :er_plan_year_status => :environment do

      effective_date = Date.new(2015,1,1)
      organizations = Organization.all_employers_by_plan_year_start_on(effective_date)

      field_names  = %w(
        fein legal_name dba employer_status plan_year_start_on plan_year_status benefit_package plan_option ref_plan_year 
        ref_plan_name ref_plan_hios_id staff_name staff_phone staff_email broker_name broker_phone broker_email
        )

      CSV.open("#{Rails.root}/public/er_plan_year_status.csv", "w") do |csv|
        csv << field_names
        organizations.each do |organization|
          organization.employer_profile.plan_years.each do |plan_year|
            plan_year.benefit_groups.each do |benefit_group|
              fein                = plan_year.employer_profile.organization.fein
              legal_name          = plan_year.employer_profile.organization.legal_name.gsub(',','')
              dba                 = plan_year.employer_profile.organization.dba.gsub(',','')
              employer_status     = plan_year.employer_profile.aasm_state
              plan_year_start_on  = plan_year.start_on
              plan_year_status    = plan_year.aasm_state
              benefit_package     = benefit_group.title.gsub(',','')
              plan_option         = benefit_group.plan_option_kind
              ref_plan_name       = benefit_group.reference_plan.name.gsub(',','')
              ref_plan_hios_id    = benefit_group.reference_plan.hios_id
              ref_plan_year       = benefit_group.reference_plan.active_year

              if plan_year.employer_profile.staff_roles.size > 0
                staff_role = plan_year.employer_profile.staff_roles.first
                staff_name = staff_role.full_name

                if staff_role.phones.present? && staff_role.phones.where(kind: "work").size > 0
                  staff_phone = staff_role.phones.where(kind: "work").first.full_phone_number
                end
                if staff_role.emails.present? && staff_role.emails.where(kind: "work").size > 0
                  staff_email = staff_role.emails.where(kind: "work").first.address
                end
              end

              if plan_year.employer_profile.active_broker.present?
                broker = plan_year.employer_profile.active_broker
                broker_name = broker.full_name

                if broker.phones.present? && broker.phones.where(kind: "work").size > 0
                  broker_phone = broker.phones.where(kind: "work").first.full_phone_number
                end
                if broker.emails.present? && broker.emails.where(kind: "work").size > 0
                  broker_email = broker.emails.where(kind: "work").first.address
                end
              end

              csv << field_names.map { |field_name| eval "#{field_name}" }
            end
          end
        end
      end
    end
  end
end