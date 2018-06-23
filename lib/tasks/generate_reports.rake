require 'csv'

namespace :generate_reports do
  desc "export conversion employer attributes"
  task conversions_employers: :environment do
    attributes = %w(fein legal_name hbx_id)
    file_name = File.expand_path("#{Rails.root}/public/results_conversion_employers.csv")

    organizations = find_organizations
    puts "Found #{organizations.count} organizations"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << attributes
      organizations.each do |org|
        csv << attributes.map {|attr| org.send(attr)}
      end
    end
    puts "Successfully exported values placed the CSV under public Directory"
  end

  def find_organizations
    BenefitSponsors::Organizations::Organization.employer_profiles.includes(:benefit_sponsorships).select {|org| org.benefit_sponsorships.first.source_kind == :mid_plan_year_conversion}
  end

  # def find_census_employees(organization)
  #   benefit_sponsorship = organization.benefit_sponsorships.first
  #   CensusEmployee.where(benefit_sponsors_employer_profile_id: organization.employer_profile.id, benefit_sponsorship_id: benefit_sponsorship.id)
  # end
  #
  # def find_enrollment_policy_id(census_employee)
  #   person = census_employee.employee_role.person
  #   hbx_id = person.hbx_id
  #   family = person.primary_family
  #   policy_id = family.active_household.hbx_enrollments.first.hbx_id
  #   dependents_hbx_ids = find_dependents_hbx_ids(family)
  #   [hbx_id, policy_id] + dependents_hbx_ids
  # end
  #
  # def find_dependents_hbx_ids(family)
  #
  #
  # end
  #
  # desc "export conversion census employee details"
  # task conversion_employees: :environment do
  #   file_name = File.expand_path("#{Rails.root}/public/results_conversion_employees.csv")
  #
  #
  #
  # end

end
