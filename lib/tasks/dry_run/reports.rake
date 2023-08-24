require_relative 'helpers'

namespace :dry_run do
  namespace :reports do

    desc "run all reports for a given year"
    task :all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      Rake::Task['dry_run:reports:renewals'].invoke(year)
      Rake::Task['dry_run:reports:determinations'].invoke(year)
      Rake::Task['dry_run:reports:notices'].invoke(year)
    end

    desc "run the renewal report for a given year"
    task :renewals, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      # who should have been renewed
      Rake::Task['dry_run:reports:renewal_eligible_families'].invoke(year)
      Rake::Task['dry_run:reports:renewal_eligible_families_who_renewed'].invoke(year)
      Rake::Task['dry_run:reports:renewal_eligible_families_who_did_not_renew'].invoke(year)
    end

    desc "run the renewal eligible families report for a given year"
    task :renewal_eligible_families, [:year] => :environment do |_t, args|
      log "Running renewal eligible families report for #{args[:year]}"
      applications = renewal_eligible_applications(args[:year])
      to_csv("renewal_eligible_families_#{args[:year]}") do |csv|
        csv << ["family_id", "primary_applicant.person_hbx_id", "primary_applicant.full_name"]
        applications.each do |app|
          csv << [app.family_id, app.primary_applicant.person_hbx_id, app.primary_applicant.full_name]
        end
      end
      log "Finished renewal eligible families report for #{args[:year]} with #{applications.size} applications."
    end

    desc "run the renewal eligible families who renewed report for a given year"
    task :renewal_eligible_families_who_renewed, [:year] => :environment do |_t, args|
      log "Running renewal eligible families who renewed report for #{args[:year]}"
      renewal_eligible_applications = renewal_eligible_applications(args[:year])
      existing_family_ids = ::FinancialAssistance::Application.by_year(args[:year]).pluck(:family_id).uniq
      # A list of applications that are renewal-eligible and have a matching family_id in the existing applications for the specified year.
      applications = renewal_eligible_applications.select { |app| existing_family_ids.include?(app.family_id) }
      to_csv("renewal_eligible_families_who_renewed_#{args[:year]}") do |csv|
        csv << ["family_id", "primary_applicant.person_hbx_id", "primary_applicant.full_name", "hbx_id" "aasm_state"]
        applications.each do |app|
          csv << [app.family_id, app.primary_applicant.person_hbx_id, app.primary_applicant.full_name, app.hbx_id, app.aasm_state]
        end
      end
      log "Finished renewal eligible families who renewed report for #{args[:year]} with #{applications.size} applications."
    end

    desc "run the renewal eligible families who did not renew report for a given year"
    task :renewal_eligible_families_who_did_not_renew, [:year] => :environment do |_t, args|
      log "Running renewal eligible families who did not renew report for #{args[:year]}"
      renewal_eligible_applications = renewal_eligible_applications(args[:year])
      existing_family_ids = ::FinancialAssistance::Application.by_year(args[:year]).pluck(:family_id)

      # A list of applications that are renewal-eligible and do not have a matching family_id in the existing applications for the specified year.
      applications = renewal_eligible_applications.reject { |app| existing_family_ids.include?(app.family_id) }
      to_csv("renewal_eligible_families_who_did_not_renew_#{args[:year]}") do |csv|
        csv << %w[family_id primary_applicant.person_hbx_id primary_applicant.full_name]
        applications.each do |app|
          csv << [app.family_id, app.primary_applicant.person_hbx_id, app.primary_applicant.full_name]
        end
      end
      log "Finished renewal eligible families who did not renew report for #{args[:year]} with #{applications.size} applications."
    end

    desc "run the determinations report for a given year"
    task :determinations, [:year] => :environment do |_t, args|
      # who should have been determined
      # who was determined
      # who was not determined
    end

    desc "run the notices report for a given year"
    task :notices, [:year] => :environment do |_t, args|
      # who should have been notified with what notice
      # who was notified with what notice
      # who was not notified with what notice
    end

    # Find notices generated for a given date range (default is all notices)
    def notices(start_date = Date.new(1900, 1, 1), end_date = TimeKeeper.date_of_record)
      Person.where(:'documents.created_at' => { :$gte => start_date, :$lte => end_date }).flat_map do |person|
        person.documents.where(:created_at.gte => start_date,
                               :created_at.lte => end_date)
      end
    end

    desc "notices generated for a given date range"
    task :notices_by_dates, [:start_date, :end_date] => :environment do |_t, args|
      start_date = args[:start_date] || TimeKeeper.date_of_record
      end_date = args[:end_date] || TimeKeeper.date_of_record
      log "Running notices report for #{start_date} to #{end_date}"
      title_code_mapping = { 'Welcome to CoverME.gov!' => 'IVLMWE',
                             'Your Plan Enrollment' => 'IVLENR',
                             'Your Eligibility Results - Tax Credit' => 'IVLERA',
                             'Your Eligibility Results - MaineCare or Cub Care' => 'IVLERM',
                             'Your Eligibility Results - Marketplace Health Insurance' => 'IVLERQ',
                             'Your Eligibility Results - Marketplace Insurance' => 'IVLERU',
                             'Open Enrollment - Tax Credit' => 'IVLOEA',
                             'Open Enrollment - Update Your Application' => 'IVLOEM',
                             'Your Eligibility Results - Health Coverage Eligibility' => 'IVLOEQ',
                             'Open Enrollment - Marketplace Insurance' => 'IVLOEU',
                             'Your Eligibility Results Consent or Missing Information Needed' => 'IVLOEG',
                             'Find Out If You Qualify For Health Insurance On CoverME.gov' => 'IVLMAT',
                             'Your Plan Enrollment for 2022' => 'IVLFRE',
                             'Action Needed - Submit Documents' => 'IVLDR0',
                             'Reminder - You Must Submit Documents' => 'IVLDR1',
                             "Don't Forget - You Must Submit Documents" => 'IVLDR2',
                             "Don't Miss the Deadline - You Must Submit Documents" => 'IVLDR3',
                             'Final Notice - You Must Submit Documents' => 'IVLDR4' }
      documents = notices(start_date, end_date)
      to_csv("notices_by_dates_#{start_date.strftime('%Y_%m_%d')}_#{end_date.strftime('%Y_%m_%d')}") do |csv|
        csv << ['HBX ID', 'Notice Title', 'Notice Code', 'Date']
        documents.each do |notice|
          csv << [notice.person.hbx_id, notice.title, title_code_mapping[notice.title], notice.created_at]
        end
      end
      log "Finished notices report for #{start_date} to #{end_date} with #{documents.size} notices."
    end

    def family_ids(year)
      beginning_of_year = Date.new(year.to_i.pred, 01, 01)
      end_of_year = Date.new(year.to_i, 12, 31)
      @family_ids ||= ::HbxEnrollment.individual_market.enrolled.where(:effective_on.gte => beginning_of_year, :effective_on.lte => end_of_year).distinct(:family_id)
    end

    def determined_family_ids(year)
      @determined_family_ids ||= determined_applications(year).distinct(:family_id)
    end

    # This method will return a collection of unique application documents based on the family_id for the given year.
    def determined_applications(year)
      family_ids = family_ids(year)

      family_ids.map do |family_id|
        ::FinancialAssistance::Application.by_year(year.to_i.pred).where(family_id: family_id).determined.created_asc.last
      end.compact
    end

    def renewal_eligible_applications(year)
      determined_applications(year).map do |app|
        app if app.eligible_for_renewal?
      end.compact
    end

    def renewal_eligible_family_ids(year)
      renewal_eligible_applications(year).map(&:family_id)
    end

    def actual_renewals(year)
      @actual_renewals ||= ::FinancialAssistance::Application.by_year(year).renewal_enrolled.distinct(:family_id)
    end
  end
end
