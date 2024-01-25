# frozen_string_literal: true

require_relative 'utils'

namespace :dry_run do
  namespace :reports do

    desc "Run reports for a given year"
    task :generate, [:year, :redeterminations, :notices] => :environment do |_t, args|
      args.with_defaults(year: TimeKeeper.date_of_record.next_year.year) # Default to next year if no year is provided
      args.with_defaults(redeterminations: true)
      args.with_defaults(notices: true)

      year = args[:year].to_i
      run_redetermination = args[:redeterminations]
      run_notices = args[:notices]

      redetermination_report_file = "redetermination_report_#{year}"
      notices_report_file = "notices_report_#{year}"

      total_eligible = 0
      total_renewed = 0
      total_determined = 0

      benchmark "Running reports for #{year}." do

        if run_redetermination
          redetermination_csv_headers = %W[family_id primary_applicant.person_hbx_id primary_applicant.full_name #{year.pred}_application_hbx_id #{year.pred}_aasm_state #{year}_application_hbx_id #{year}_application_aasm_state redetermination_errors]
          to_csv(redetermination_report_file, "w+") { |csv| csv << redetermination_csv_headers }
        end

        if run_notices
          notices_csv_headers = %w[family_id primary_applicant.person_hbx_id primary_applicant.full_name notice_title notice_description notice_date]
          to_csv(notices_report_file, "w+") { |csv| csv << notices_csv_headers }
        end

        each_renewal_eligible_app year do |app|
          if run_redetermination
            # For each renewal eligible application, see if there is a renewed application and if so, what is the status. If there is no renewal application, log the errors. Either way, log the renewal eligible application.
            renewed_app = ::FinancialAssistance::Application.by_year(year).where(family_id: app.family_id)&.first
            redetermination_errors = renewed_app&.is_determined? ? nil : redetermination_errors(app)
            redetermination_csv_data = [app.family_id, app.primary_applicant.person_hbx_id, app.primary_applicant.full_name, app.hbx_id, app.aasm_state, renewed_app&.hbx_id, renewed_app&.aasm_state, redetermination_errors]
            to_csv(redetermination_report_file) { |csv| csv << redetermination_csv_data }

            total_eligible += 1
            total_renewed += 1 if renewed_app.present?
            total_determined += 1 if renewed_app&.is_determined?
          end

          next unless run_notices
          # For each renewal eligible application, see if there are any notices generated for the primary applicant.
          notices = notices_for_person(app.primary_applicant.person_hbx_id, dry_run_start_date, dry_run_end_date)
          notices.each do |notice|
            notices_csv_data = [app.family_id, app.primary_applicant.person_hbx_id, app.primary_applicant.full_name, notice.title, notice_description(notice.title), notice.created_at]
            to_csv(notices_report_file) { |csv| csv << notices_csv_data }
          end
        end

        log "Total applications eligible for renewal: #{total_eligible}", "Total applications renewed: #{total_renewed}", "Total applications determined: #{total_determined}" if run_redetermination
        log "Finished report for #{args[:year]}."
      end
    end

    # Find notices generated for a given date range (default is all notices)
    def notices(start_date = Date.new(1900, 1, 1), end_date = TimeKeeper.date_of_record)
      Person.where(:'documents.created_at' => { :$gte => start_date, :$lte => end_date }).flat_map do |person|
        person.documents.where(:created_at.gte => start_date,
                               :created_at.lte => end_date)
      end
    end

    def notices_for_person(person_hbx_id, start_date = Date.new(1900, 1, 1), end_date = TimeKeeper.date_of_record)
      person = Person.find_by(hbx_id: person_hbx_id)
      person.documents.where(:created_at.gte => start_date,
                             :created_at.lte => end_date)
    end

    def notice_description(code)
      {
        'Welcome to CoverME.gov!' => 'IVLMWE',
        'Your Plan Enrollment' => 'IVLENR',
        'Your Eligibility Results - Tax Credit' => 'IVLERA',
        'Your Eligibility Results - Medicaid or CHIP' => 'IVLERM',
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
        'Final Notice - You Must Submit Documents' => 'IVLDR4'
      }[code]
    end

    desc "notices generated for a given date range"
    task :notices_by_dates, [:start_date, :end_date] => :environment do |_t, args|
      start_date = args[:start_date] || TimeKeeper.date_of_record
      end_date = args[:end_date] || TimeKeeper.date_of_record
      start_date = Date.parse(start_date) if start_date.is_a?(String)
      end_date = Date.parse(end_date) if end_date.is_a?(String)

      log "Running notices report for #{start_date} to #{end_date}"
      documents = notices(start_date, end_date)
      to_csv("notices_by_dates_#{start_date.strftime('%Y_%m_%d')}_#{end_date.strftime('%Y_%m_%d')}") do |csv|
        csv << ['HBX ID', 'Notice Title', 'Notice Code', 'Date']
        documents.each do |notice|
          csv << [notice.person.hbx_id, notice.title, notice_description(notice.title), notice.created_at]
        end
      end
      log "Finished notices report for #{start_date} to #{end_date} with #{documents.size} notices."
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
        latest_determined_for_families(renewal_year.pred, family_id_slice).each do |app|
          yield app if app.eligible_for_renewal?
        end
      end
    end

    # They are only candidates because for the sake of time we dont check the eligible_for_renewal? method and rather just check if there is a determined application for the family in the previous year.
    def missing_faa_renewal_candidates(renewal_year)
      family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)
      latest_determined_for_families(renewal_year.pred, family_ids).pluck(:family_id) - ::FinancialAssistance::Application.by_year(renewal_year).where(:family_id.in => family_ids).pluck(:family_id)
    end

    # Retrieve the latest determined application for each family in the year prior to the renewal year.
    def latest_determined_for_families(renewal_year, family_ids = nil)
      renewal_year ||= TimeKeeper.date_of_record.year + 1
      family_ids ||= ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)
      latest_applications = ::FinancialAssistance::Application.collection.aggregate([
                                                                                      {
                                                                                        '$match': {
                                                                                          'assistance_year': renewal_year.pred,
                                                                                          'aasm_state': 'determined',
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
                                                                                          '_id': '$family_id',
                                                                                          'latest_application_id': { '$first': '$_id' }
                                                                                        }
                                                                                      }
                                                                                    ])

      latest_application_ids = latest_applications.map { |doc| doc['latest_application_id'] }

      ::FinancialAssistance::Application.where(:_id.in => latest_application_ids)
    end

    # Try and find any know issues with the application that would prevent it from being renewed or re-determined.
    def redetermination_errors(app)
      # Mirrors the validations from the application model. We need to do this manually because we want all possible errors, not just the first one.
      # enroll/components/financial_assistance/app/models/financial_assistance/application.rb#is_application_valid?
      app.required_attributes_valid?
      app.relationships_complete?
      app.applicants_have_valid_addresses?
      app.errors.full_messages.join('\n')
    end

  end
end
