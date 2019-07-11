require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employer plan year application status by effective date"
    task :employer_plan_year_status => :environment do

      effective_date = Date.new(2015,1,1)
      benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_application_start_on_or_after(effective_date)

      field_names  = %w(
        fein legal_name dba employer_status plan_year_start_on plan_year_status benefit_package plan_option ref_plan_year 
        ref_plan_name ref_plan_hios_id staff_name staff_phone staff_email broker_name broker_phone broker_email
        )

      CSV.open("#{Rails.root}/public/er_plan_year_status.csv", "w", force_quotes: true) do |csv|
        csv << field_names
        benefit_sponsorships.each do |benefit_sponsorship|
          organization = benefit_sponsorship.organization
          employer_profile = organization.employer_profile
          benefit_sponsorship.benefit_applications.each do |benefit_application|

            benefit_application.benefit_packages.each do |package|
              fein                = organization.fein
              legal_name          = organization.legal_name.gsub(',','')
              dba                 = organization.dba.gsub(',','')
              employer_status     = benefit_sponsorship.aasm_state
              plan_year_start_on  = benefit_application.start_on
              plan_year_status    = benefit_application.aasm_state
              benefit_package     = package.title.gsub(',','')
              plan_option         = package.plan_option_kind
              ref_plan_name       = package.reference_plan.name.gsub(',','')
              ref_plan_hios_id    = package.reference_plan.hios_id
              ref_plan_year       = package.reference_plan.active_year

              if employer_profile.staff_roles.size > 0
                staff_role = employer_profile.staff_roles.first
                staff_name = staff_role.full_name

                if staff_role.phones.present? && staff_role.phones.where(kind: "work").size > 0
                  staff_phone = staff_role.phones.where(kind: "work").first.full_phone_number
                end
                if staff_role.emails.present? && staff_role.emails.where(kind: "work").size > 0
                  staff_email = staff_role.emails.where(kind: "work").first.address
                end
              end

              if employer_profile.active_broker.present?
                broker = employer_profile.active_broker
                broker_name = broker.full_name

                if broker.phones.present? && broker.phones.where(kind: "work").size > 0
                  broker_phone = broker.phones.where(kind: "work").first.full_phone_number
                end
                if broker.emails.present? && broker.emails.where(kind: "work").size > 0
                  broker_email = broker.emails.where(kind: "work").first.address
                end
              end

              csv << field_names.map do |field_name| 
                if field_name == "fein"
                  '="' + eval(field_name) + '"'
                else
                  eval("#{field_name}")
                end
              end
            end
          end
        end
      end
    end
  end
end