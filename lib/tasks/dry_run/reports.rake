require_relative 'helpers'

namespace :dry_run do
  namespace :reports do

    desc "run all reports for a given year"
    task :all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      Rake::Task['dry_run:reports:application_renewals'].invoke(year)
      # Not yet implemented
      # Rake::Task['dry_run:reports:determinations'].invoke(year)
      # Rake::Task['dry_run:reports:notices'].invoke(year)
    end

    desc "Run the renewal report for a given year"
    task :application_renewals, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      benchmark "Running renewal report for #{year}." do
        renewal_eligible_file = "renewal_eligible_families_#{year}"
        renewal_not_renewed_file = "renewal_eligible_families_who_did_not_renew_#{year}"
        renewal_renewed_file = "renewal_eligible_families_who_renewed_#{year}"
        renewed_family_ids = ::FinancialAssistance::Application.by_year(year).pluck(:family_id)

        # Define CSV headers
        csv_headers = %w[family_id primary_applicant.person_hbx_id primary_applicant.full_name]

        # Create CSV files with headers
        to_csv(renewal_eligible_file, "w+") { |csv| csv << csv_headers }
        to_csv(renewal_not_renewed_file, "w+") { |csv| csv << csv_headers.concat(%w[errors]) }
        to_csv(renewal_renewed_file, "w+") { |csv| csv << csv_headers.concat(%w[application_hbx_id aasm_state]) }

        each_renewal_eligible_app year do |app|
          csv_data = [app.family_id, app.primary_applicant.person_hbx_id, app.primary_applicant.full_name]

          to_csv(renewal_eligible_file) { |csv| csv << csv_data }

          if renewed_family_ids.include?(app.family_id)
            to_csv(renewal_renewed_file) { |csv| csv << csv_data.concat([app.hbx_id, app.aasm_state]) }
          else
            to_csv(renewal_not_renewed_file) { |csv| csv << csv_data.concat([application_renewal_errors(app)]) }
          end

        end

        log "Finished renewal report for #{args[:year]}."
      end
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

    # To avoid loading each application into memory at once we yield the results in batches.
    # @param [Integer] renewal_year
    # @param [Integer] batch_size - number of family_ids to process at once (default 1000)
    # @yield [FinancialAssistance::Application] - the application that is eligible for renewal
    # @return [void]
    # @example
    #  each_renewal_eligible_app(2021) do |app|
    #   puts app.family_id
    # end
    # @note - this method is used in the renewal report
    def each_renewal_eligible_app(renewal_year, batch_size = 1000)
      family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)
      family_ids.each_slice(batch_size) do |family_id_slice|
        results = ::FinancialAssistance::Application.by_year(renewal_year.pred).determined.where(:family_id.in => family_id_slice).to_a.group_by(&:family_id).transform_values { |group| group.max_by(&:created_at) }.select { |_, v| v.eligible_for_renewal? }.values
        results.each do |app|
          yield app
        end
      end
    end

    # Try and find any know issues with the application that would prevent it from being renewed.
    def application_renewal_errors(app)
      errors = []
      errors << missing_in_state_address(app)
      errors << missing_relationships(app)
      errors.compact.join("\n")
    end

    def missing_in_state_address(app)
      message = "Family primary applicant is missing an in-state address."
      # @todo - get state from config and only check if ff is enabled
      # app.family.primary_applicant.person.addresses.where(state: "DC").empty? ? message : nil
    end

    def missing_relationships(app)
      missing = app.find_missing_relationships
      "Family members are missing relationships: #{missing}." unless missing.empty?
    end
  end
end
