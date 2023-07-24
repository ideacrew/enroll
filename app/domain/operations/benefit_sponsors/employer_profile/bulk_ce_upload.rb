# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module BenefitSponsors
    module EmployerProfile
      # This class will persist Census Employees to roster
      class BulkCeUpload
        send(:include, Dry::Monads[:result, :do, :try])
        include EventSource::Command

        def call(params)
          _values = yield validate(params)
          file = yield fetch_s3_file(params[:uri], params[:extension])
          result = yield process_file(file, params[:employer_profile_id])
          Success(result)
        end

        private

        def validate(params)
          errors = []
          errors << 'uri is missing' unless params[:uri]
          errors << 'employer profile id is missing' unless params[:employer_profile_id]
          errors << 'file extension is missing' unless params[:extension]
          errors.empty? ? Success(params) : Failure(errors)
        end

        def fetch_s3_file(uri, extension)
          s3_object = Aws::S3Storage.find(uri)
          if s3_object
            file = Tempfile.new(['temp', extension])
            file.binmode
            file.write s3_object
            file.close
            Success(file)
          else
            Failure('could not find the URI')
          end
        end

        def process_file(file, employer_profile_id)
          organization = ::BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(employer_profile_id)).first
          employer_profile = organization.employer_profile
          roster_upload_form = ::BenefitSponsors::Forms::RosterUploadForm.call(file, employer_profile)
          if roster_upload_form.save
            census_employees_count = roster_upload_form.census_records.length
            Success("Successfully uploaded census employees: #{census_employees_count} to the roster")
          else
            Failure(roster_upload_form.errors)
          end
        end
      end
    end
  end
end