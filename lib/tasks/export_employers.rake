require 'csv'

namespace :employers do
  desc "Export employers to csv."
  task :export => [:environment] do
    employers = Organization.where("employer_profile" => {"$exists" => true}).map(&:employer_profile)
    EXCLUDED_ATTRIBUTES = %w(aasm_state updated_at created_at)
    INCLUDED_ATTRIBUTES = %w(employer_max_amt employee_max_amt first_dependent_max_amt over_one_dependents_max_amt elected_plan_ids)
    MONEY_ATTRIBUTES = %w(employer_max_amt employee_max_amt first_dependent_max_amt over_one_dependents_max_amt)
    ARRAY_ATTRIBUTES = %w(elected_plan_ids)
    FILE_PATH = Rails.root.join "employer_export.csv"

    def extract_value(key, value)
      return nil if value.nil?

      if MONEY_ATTRIBUTES.include? key
        return value["cents"]
      elsif ARRAY_ATTRIBUTES.include? key
        ""
      else
        return value
      end
    end

    def keys_values(document)
      return_values = []
      document.attribute_names.each do |key|
        #debugger if document.class == BenefitGroup && key == "employer_max_amt"
        next if ((document.attributes[key].is_a? BSON::Document) || (document.attributes[key].is_a? Array)) && (!INCLUDED_ATTRIBUTES.include? key)
        return_values << (extract_value(key, document.attributes[key]) || document.attributes[key].to_s)
      end
      return_values
    end

    def add_to_csv(type, object, csv)
      op = [type]
      op.append keys_values(object)
      csv << op.flatten
    end

    def schema(csv)
      models = [EmployerProfile, Organization, OfficeLocation, Address, Phone, EmployerProfileAccount, BrokerAgencyAccount, CensusEmployee,
                CensusDependent, PlanYear, BenefitGroup, RelationshipBenefit, Plan]

      models.each do |model|
        csv << model.attribute_names.unshift(model.to_s)
      end
    end

    CSV.open(FILE_PATH, "w") do |csv|
      schema(csv)

      employers.each do |employer|
        add_to_csv("EmployerProfile", employer, csv)
        add_to_csv("Organization", employer.organization, csv)

        employer.organization.office_locations.each do |office_location|
          add_to_csv("OfficeLocation", office_location, csv)
          add_to_csv("Address", office_location.address, csv)
          add_to_csv("Phone", office_location.phone, csv)
        end

        if employer.employer_profile_account.present?
          add_to_csv("EmployerProfileAccount", employer.employer_profile_account, csv)
        end

        employer.broker_agency_accounts.each do |broker_agency_account|
          add_to_csv("BrokerAgencyAccount", broker_agency_account, csv)
        end

        employer.census_employees.each do |census_employee|
          add_to_csv("CensusEmployee", census_employee, csv)

          census_employee.census_dependents.each do |census_dependent|
            add_to_csv("CensusDependent", census_dependent, csv)
          end
        end

        employer.plan_years.each do |plan_year|
          add_to_csv("PlanYear", plan_year, csv)

          plan_year.benefit_groups.each do |benefit_group|
            add_to_csv("BenefitGroup", benefit_group, csv)

            benefit_group.relationship_benefits.each do |relationship_benefit|
              add_to_csv("RelationshipBenefit", relationship_benefit, csv)
            end

            benefit_group.elected_plans.each do |elected_plan|
              add_to_csv("Plan (elected plan)", elected_plan, csv)
            end
          end
        end
      end

    end

    puts "Output written to #{FILE_PATH}"

  end
end