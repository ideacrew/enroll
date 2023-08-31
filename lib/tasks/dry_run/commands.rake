require_relative 'helpers'

namespace :dry_run do
  namespace :commands do
    def update_open_enrollment(title, start_date: nil, end_date: nil)
      bcp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.find_by(title: title)

      log("No benefit coverage period found for #{title}") && exit unless bcp

      updates = {}
      updates[:open_enrollment_start_on] = Date.strptime(start_date.to_s, "%m/%d/%Y") if start_date.present?
      updates[:open_enrollment_end_on] = Date.strptime(end_date.to_s, "%m/%d/%Y") if end_date.present?

      bcp.update(updates) unless updates.empty?
    end

    desc "initiate open enrollment for a given year"
    task :open_enrollment, [:year] => :environment do |t, args|
      year = args[:year].to_i
      log "Ending open enrollment for #{year.pred}"
      update_open_enrollment("Individual Market Benefits #{year.pred}", end_date: TimeKeeper.date_of_record.yesterday - 2)
      log "Beginning open enrollment for #{args[:year]}"
      update_open_enrollment("Individual Market Benefits #{year}", start_date: TimeKeeper.date_of_record.yesterday, end_date: Date.new(year).end_of_year)
    end

    desc "run the renewal process for a given year"
    task :renew_applications, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Beginning renewal process for #{year}"
      result = FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::RequestAll.new.call({ renewal_year: year })
      log "Renewal process for #{year} - #{result_type(result)}", result_message(result)
    end

    desc "Run enrollment renewals for a given year"
    task :renew_enrollments, [:year] => :environment do |_t, args|
      log "Beginning enrollment renewal process for #{args[:year]}"
      renewal_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period
      log("Missing renewal coverage period for #{args[:year]}") && exit unless renewal_coverage_period
      log("Renewal coverage period for #{args[:year]} is not open.") && exit unless renewal_coverage_period&.open_enrollment_start_on <= TimeKeeper.date_of_record
      Enrollments::IndividualMarket::OpenEnrollmentBegin.new.process_renewals
    end

    desc "run the determination process for a given year"
    task :determine_applications, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Beginning determination process for #{year}"
      result = FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::DetermineAll.new.call({ renewal_year: year })
      log "Determination process for #{year} - #{result_type(result)}", result_message(result)
    end

    desc "Run the post-renewals notice triggers for a given year"
    task :notify, [:year] => :environment do |_t, args|
      year = args[:year].to_i

      # distinct family IDs from Financial Assistance Applications that have been determined (presumably approved) for the given renewal year.
      determined_families = ::FinancialAssistance::Application.determined.by_year(year).distinct(:family_id)
      # a list of distinct family IDs from all Financial Assistance Applications for the given renewal year.
      faa_families = ::FinancialAssistance::Application.by_year(year).distinct(:family_id)
      # distinct family IDs from HbxEnrollments that are active, enrolled in the current year, and not associated with any family from faa_families.
      oeq_families = HbxEnrollment.active.enrolled.current_year.where(:family_id.nin => faa_families).distinct(:family_id)
      # distinct family IDs from HbxEnrollments that are active, enrolled in the current year, and associated with families from faa_families but not with families from determined_families.
      oeg_families = HbxEnrollment.active.enrolled.current_year.where(:family_id.in => (faa_families - determined_families)).distinct(:family_id)

      families_to_notify = (oeq_families + oeg_families).uniq

      results = families_to_notify.map do |family_id|
        family = Family.find_by(id: family_id)
        next unless family

        result = Operations::Notices::IvlOeReverificationTrigger.new.call(family: family)
        "Notice for family_id: #{family_id} - #{result.success? ? "success" : "failure"}"
      rescue => e
        log "Error triggering notice event due to #{e.message} for family_id #{family_id}", e.backtrace&.join("\n")
      end
      log "Triggered notices for #{results.count} families.", results.join("\n")
    end
  end
end
