# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'csv'

module Operations
  # export evidences
  module Eligibilities
    # Generate family evidence data report
    class FamilyDataExportProcessor
      include Dry::Monads[:do, :result]

      DR_NOTICES = {
        :DR0 => "Action Needed - Submit Documents",
        :DR1 => "Reminder - You Must Submit Documents",
        :DR2 => "Don't Forget - You Must Submit Documents",
        :DR3 => "Don't Miss the Deadline - You Must Submit Documents",
        :DR4 => "Final Notice - You Must Submit Documents"
      }.freeze

      # @param [Hash] opts Options to update evidence due on dates
      # @option opts [Integer] :offset required
      # @option opts [Integer] :limit required
      # @option opts [Integer] :assistance_year required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        family_data = yield construct_family_data(values)

        Success(family_data)
      end

      private

      def validate(params)
        return Failure('offset missing') unless params[:offset]
        return Failure('limit missing') unless params[:limit]
        return Failure('assistance year missing') unless params[:assistance_year]

        Success(params)
      end

      def construct_family_data(values)
        logger = init_logger
        file_name = filename(values)
        index = 0
        CSV.open(file_name, 'w', force_quotes: true) do |csv|
          csv << columns
          Family.all.skip(values[:offset]).limit(values[:limit]).no_timeout.each do |family|
            index += 1
            puts "processed #{index} families" if index % 100 == 0
            logger.info "processed #{index} families" if index % 100 == 0

            family_data = ::Operations::Eligibilities::FamilyEvidencesDataExport.new.call(
              family: family,
              assistance_year: values[:assistance_year] || TimeKeeper.date_of_record.year
            ).success

            ed_status = family.eligibility_determination&.outstanding_verification_status
            ed_due_date = family.eligibility_determination&.outstanding_verification_earliest_due_date
            primary_person = family.primary_person
            dr_notice_creation_dates = get_dr_notice_creation_dates(primary_person)
            family_data.each { |member_row| csv << (member_row + [ed_status.to_s, ed_due_date] + dr_notice_creation_dates + [primary_person.consumer_role&.contact_method]) }
          rescue StandardError => e
            logger.info "FamilyDataExportProcessor - Error processing Family with hbx_id: #{family&.hbx_assigned_id}, message: #{e.message}" unless Rails.env.test?
          end
        end

        Success(file_name)
      rescue StandardError => e
        logger.info "FamilyDataExportProcessor - Error raised. message: #{e.message}" unless Rails.env.test?
        Success(file_name)
      end

      def get_dr_notice_creation_dates(person)
        DR_NOTICES.inject([]) do |data, (_type,title)|
          data << person.documents.where(title: title).last&.created_at&.strftime('%Y_%m_%d %H:%M')
          data
        end
      end

      def init_logger
        Logger.new(
          "#{Rails.root}/log/build_family_eligibility_data_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )
      end

      def filename(values)
        "#{Rails.root}/family_eligibility_data_export_#{values[:offset]}_#{values[:limit]}_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
      end

      # rubocop:disable Metrics/MethodLength
      def columns
        headings = [
          'Family Hbx ID',
          'Primary Hbx ID',
          'Is Subscriber?',
          'Member Hbx ID',
          'SSN',
          'Member First Name',
          'Member Last Name',
          'Member Is Active?',
          'Health Cov Hbx ID',
          'Health Cov Effective On',
          'Health Cov Member Start',
          'Health Cov Member End',
          'Other Health Covs',
          'Dental Cov Hbx ID',
          'Dental Cov Effective On',
          'Dental Cov Member Start',
          'Dental Cov Member End',
          'Other Dental Covs',
          'Citizen Kind',
          'Immigrant Kind',
          'SSN Evi Status',
          'SSN Evi Due Date',
          'American Ind Evi Status',
          'American Ind Evi Due Date',
          'Citizenship Evi Status',
          'Citizenship Evi Due Date',
          'Immigration Evi Status',
          'Immigration Evi Due Date',
          'Aptc Amt',
          'CSR',
          'Application Hbx ID',
          'Application Created At',
          'Applicant Applying Coverage?',
          'Cur Mth Earned Income Amt',
          'Cur Mth UnEarned Income Amt',
          'Income Status',
          'Income Due Date',
          'Income Response',
          'Esi Status',
          'Esi Due Date',
          'Esi Response',
          'Non Esi Status',
          'Non Esi Due Date',
          'Non Esi Response',
          'Local Mec Status',
          'Local Mec Due Date',
          'Local Mec Response',
          'Esi Updated?',
          'Local Mec Updated?',
          'Eligibility Determination Status',
          'Eligibility Determination Due Date',
          'DR0 Created On',
          'DR1 Created On',
          'DR2 Created On',
          'DR3 Created On',
          'DR4 Created On',
          'Communication Preference'
        ]

        headings.insert(headings.find_index('Aptc Amt'), "Residency Evi Status", "Residency Evi Due Date") if EnrollRegistry.feature_enabled?(:location_residency_verification_type)
        headings
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
