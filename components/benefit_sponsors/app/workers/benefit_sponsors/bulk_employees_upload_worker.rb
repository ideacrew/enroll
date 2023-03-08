# frozen_string_literal: true

module BenefitSponsors
  # Class to create employees from csv file upload
  class BulkEmployeesUploadWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(file_name, content_type, employer_profile_id, user_email)
      organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(employer_profile_id)).first
      employer_profile = organization.employer_profile

      file = ActionDispatch::Http::UploadedFile.new({
                                                      :filename => file_name,
                                                      :type => content_type,
                                                      :tempfile => File.new("#{Rails.root}/public/#{file_name}")
                                                    })

      roster_upload_form = BenefitSponsors::Forms::RosterUploadForm.call(file, employer_profile)
      roster_upload_count = roster_upload_form.census_records.length
      begin
        if roster_upload_form.save
          # success mail
          EmployeeUploadMailer.success_email(user_email, roster_upload_count).deliver_now
        else
          # failure email
          EmployeeUploadMailer.failure_email(user_email).deliver_now
        end
      rescue StandardError => e
        # sending an error email
        EmployeeUploadMailer.error_email(user_email, e.message).deliver_now
      ensure
        FileUtils.rm file.tempfile
      end
    end
  end
end
