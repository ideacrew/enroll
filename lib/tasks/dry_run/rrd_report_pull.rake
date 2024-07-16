# frozen_string_literal: true

require 'rake'
require "csv"

# The task to run is RAILS_ENV=production bundle exec rake dry_run:pull_rrd_data year=2024
namespace :dry_run do
  desc "Pull data for the RRD report for a given year"
  task pull_rrd_data: :environment do
    year = ENV['year'].to_i

    # Application CSV
    def pull_application_data(filename, applications)
      headers = ["Member ID",
                 "Primary Member ID",
                 "Application ID",
                 "Applying For Coverage",
                 "APTC Amount",
                 "APTC/CSR Eligible",
                 "Citizenship Status",
                 "CSR",
                 "Immigration Status",
                 "Income",
                 "IRS Consent",
                 "Medicaid FPL",
                 "Medicaid/CHIP Eligible",
                 "Tobacco User",
                 "Totally Ineligible",
                 "UQHP Eligble"]
      CSV.open(filename, "w", force_quotes: true) do |csv|
        csv << headers
        applications.each do |application|
          application.applicants.each do |applicant|
            csv << [applicant.person_hbx_id,
                    application.primary_applicant.person_hbx_id,
                    application._id,
                    applicant.is_applying_coverage,
                    applicant.eligibility_determination&.max_aptc,
                    applicant.eligibility_determination&.is_csr_eligible? && applicant.eligibility_determination&.is_aptc_eligible?,
                    applicant.citizen_status,
                    applicant.eligibility_determination&.csr_percent_as_integer,
                    applicant.immigration_doc_statuses,
                    applicant.net_annual_income,
                    application.is_renewal_authorized,
                    applicant.magi_as_percentage_of_fpl,
                    applicant.is_medicaid_chip_eligible,
                    applicant.is_tobacco_user,
                    applicant.is_totally_ineligible,
                    applicant.is_without_assistance]
          end
        end
      end
    end


    # Notice CSV
    def pull_notice_data(filename, applications, current_year)
      headers = ["Primary Member ID",
                 "OEM Date",
                 "OEA Date",
                 "OEU Date",
                 "ENR Date"]
      CSV.open(filename, "w", force_quotes: true) do |csv|
        csv << headers
        applications.each do |application|
          person_id = application.primary_applicant.person_hbx_id
          person = Person.where(hbx_id: person_id).first
          csv << [person.hbx_id,
                  pull_notice_dates(person, current_year, "OEM").first,
                  pull_notice_dates(person, current_year, "OEA").first,
                  pull_notice_dates(person, current_year, "OEU").first,
                  pull_notice_dates(person, current_year, "ENR").first]
        end
      end
    end


    # Notice Helper Functions
    def notice_title(code)
      {
        'OEM' => 'Open Enrollment - Update Your Application',
        'OEA' => 'Open Enrollment - Tax Credit',
        'OEU' => 'Open Enrollment - Marketplace Insurance',
        'ENR' => 'Your Plan Enrollment'
      }[code]
    end

    def pull_notice_dates(person, current_year, notice_code)
      notice_title = notice_title(notice_code)
      start_date = Date.new(current_year, 1, 1)
      end_date = Date.new(current_year, 12, 31)
      person.documents.where(:created_at.gte => start_date,
                             :created_at.lte => end_date,
                             :title => notice_title).map(&:created_at)
    end


    # Enrollment Query CSV
    def pull_enrollment_data(filename, enrollments)
      headers = ["Primary Member ID",
                 "Subscriber ID",
                 "Member HBX ID",
                 "APTC",
                 "CSR",
                 "HIOS ID",
                 "Enrollment ID",
                 "Metal Level",
                 "Rating Area",
                 "Osse Indicator",
                 "Tobacco Use"]
      CSV.open(filename, "w", force_quotes: true) do |csv|
        csv << headers
        enrollments.each do |enrollment|
          tobacco_indicator = {}
          enr_members = []
          enrollment.hbx_enrollment_members.each do |member|
            tobacco_indicator[member.hbx_id] = member.tobacco_use_value_for_edi
            enr_members << member.person&.hbx_id
          end
          csv << [enrollment.family.primary_person.hbx_id,
                  enrollment.subscriber.hbx_id,
                  enr_members,
                  enrollment.applied_aptc_amount,
                  enrollment.product.csr_variant_id,
                  enrollment.product.hios_id,
                  enrollment.hbx_id,
                  enrollment.product.metal_level,
                  enrollment.rating_area.exchange_provided_code,
                  enrollment.ivl_osse_eligible?,
                  tobacco_indicator]
        end
      end
    end

    def pull_member_data(filename, families, _year)
      headers = ["Member ID",
                 "Primary Member ID",
                 "Relationship to Primary Member",
                 "DOB",
                 "Applying For Coverage",
                 "Citizenship Status",
                 "Incarceration Status",
                 "Address County",
                 "Address State",
                 "Address Zip",
                 "Tobacco Status",
                 "Individual Market Role",
                 "Disabled",
                 "Active",
                 "Deleted from Manage Family"
                 "Physically Disabled",
                 "Age Off Excluded",
                 "Temporarily Out Of State"]
      CSV.open(filename, "w", force_quotes: true) do |csv|
        csv << headers
        families.each do |family|
          family.family_members.each do |member|
            person = member.person
            csv << [person.hbx_id,
                    family.primary_person&.hbx_id,
                    member.primary_relationship,
                    person.dob,
                    person.is_applying_coverage,
                    person.consumer_role&.citizen_status,
                    person.is_incarcerated,
                    person.home_address&.county,
                    person.home_address&.state,
                    person.home_address&.zip,
                    person.tobacco_use,
                    person.active_individual_market_role,
                    person.is_disabled,
                    person.is_active || person.consumer_role&.is_active,
                    member.is_active,
                    person.is_physically_disabled,
                    person.age_off_excluded,
                    person.is_temporarily_out_of_state]
          end
        end
      end
    end


    # Common Search Criteria
    def renewal_search_criteria(renewal_year)
      renewal_statuses = HbxEnrollment::RENEWAL_STATUSES.map(&:to_s)
      HbxEnrollment.collection.aggregate([
      {
        '$match': {
          'aasm_state' => { '$in' => HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
          'effective_on' => { '$gte' => Date.new(renewal_year, 1, 1), '$lte' => Date.new(renewal_year, 12, 31) },
          'kind' => { '$nin' => ['employer_sponsored', 'employer_sponsored_cobra'] },
          '$or' => [
            {'workflow_state_transitions.from_state': { '$in' => renewal_statuses }},
            {'workflow_state_transitions.to_state': { '$in' => renewal_statuses }}
        ]
        }
      },
      {
        "$project" => {"family_id" => "$family_id",
                       "hbx_id" => "$hbx_id"}
      }
      ])
    end


    # Application Query Data
    def latest_determined_application(current_year, family_ids = nil)
      family_ids ||= ::HbxEnrollment.individual_market.enrolled.where(:effective_on.gte => Date.new(current_year, 1, 1),
                                                                      :effective_on.lte => Date.new(current_year, 12, 31)).distinct(:family_id)
      latest_applications = ::FinancialAssistance::Application.collection.aggregate([
      {
        '$match': {
          'assistance_year': current_year,
          'aasm_state': "determined",
          'family_id': { '$in': family_ids }
        }
      },
      {
        '$sort': {
          'family_id': 1,
          'created_at': -1
        }
      },
      {
        '$group': {
          '_id': "$family_id",
          'latest_application_id': { '$first': "$_id" }
        }
      }
      ])

      latest_application_ids = latest_applications.map { |doc| doc["latest_application_id"] }

      ::FinancialAssistance::Application.where(:_id.in => latest_application_ids)
    end

    def redetermined_application_query(renewal_year, family_ids)
      renewal_applications = ::FinancialAssistance::Application.collection.aggregate([
      {
        '$match': {
          'assistance_year': renewal_year,
          'aasm_state': "determined",
          'family_id': { '$in': family_ids }
        }
      },
      {
        '$sort': {
          'family_id': 1,
          'created_at': 1
        }
      },
      {
        '$group': {
          '_id': "$family_id",
          'renewal_application_id': { '$first': "$_id" }
        }
      }
      ])

      renewal_application_ids = renewal_applications.map { |doc| doc["renewal_application_id"] }

      ::FinancialAssistance::Application.where(:_id.in => renewal_application_ids)
    end


    # Enrollment Query Data
    def latest_active_enrollments(current_year)
      HbxEnrollment.individual_market.enrolled.where(:effective_on.gte => Date.new(current_year, 1, 1),
                                                     :effective_on.lte => Date.new(current_year, 12, 31))
    end

    def passive_renewal_enrollments(renewal_year)
      enrollment_ids = renewal_search_criteria(renewal_year).map { |doc| doc['hbx_id'] }.uniq
      HbxEnrollment.where(:hbx_id.in => enrollment_ids)
    end

      # Member Query Data
    def families_with_enrollment_in_current_year(current_year)
      family_ids = ::HbxEnrollment.individual_market.where(:effective_on.gte => Date.new(current_year, 1, 1),
                                                           :effective_on.lte => Date.new(current_year, 12, 31),
                                                           :aasm_state.nin => ['shopping']).distinct(:family_id)
      Family.where(:id.in => family_ids)
    end


    # Create CSVs
    def create_application_sets(current_year, renewal_year, redetermined_applications)
      latest_application = latest_determined_application(current_year)

      pull_application_data("latest_applications_#{current_year}.csv", latest_application)
      pull_application_data("redetermined_applications_#{renewal_year}.csv", redetermined_applications)
    end

    def create_notice_sets(current_year, renewal_year, redetermined_applications)
      pull_notice_data("renewal_notices_#{renewal_year}.csv", redetermined_applications, current_year)
    end

    def create_enrollment_sets(current_year, renewal_year)
      latest_active_enrollments = latest_active_enrollments(current_year)
      passive_renewal_enrollments = passive_renewal_enrollments(renewal_year)

      pull_enrollment_data("latest_active_enrollments_#{current_year}.csv", latest_active_enrollments)
      pull_enrollment_data("passive_renewal_enrollments_#{renewal_year}.csv", passive_renewal_enrollments)
    end

    def create_member_sets(current_year)
      current_year_families = families_with_enrollment_in_current_year(current_year)

      pull_member_data("members_with_enrollment_#{current_year}.csv", current_year_families, current_year)
    end

    # Shared Data
    renewal_year = year + 1
    family_ids_with_renewals = renewal_search_criteria(renewal_year).map { |doc| doc['family_id'] }.uniq
    redetermined_applications = redetermined_application_query(renewal_year, family_ids_with_renewals)

    create_application_sets(year, renewal_year, redetermined_applications)
    create_notice_sets(year, renewal_year, redetermined_applications)
    create_enrollment_sets(year, renewal_year)
    create_member_sets(year)

  end
end

