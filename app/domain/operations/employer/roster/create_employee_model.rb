# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Employer
    module Roster
      # This class will persist employee to DB
      class CreateEmployeeModel
        send(:include, Dry::Monads[:result, :do, :try])
        include EventSource::Command

        def call(params)
          file = yield fetch_s3_file(params[:uri], params[:extension])
          result = yield process_file(file, params[:employer_profile_id])
          model = yield persist(result)

          Success(model)
        end

        private

        def fetch_s3_file(uri,extension)
          file = Tempfile.new(['temp',extension])
          file.binmode
          file.write Aws::S3Storage.find(uri)
          file.close
          Success(file)
        end

        def process_file(file, employer_profile_id)
          organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(_id: BSON::ObjectId.from_string(employer_profile_id)).first
          employer_profile = organization.employer_profile
          roster_upload_form = BenefitSponsors::Forms::RosterUploadForm.call(file, employer_profile)
          Success(roster_upload_form)
        end

        def persist(object)
          result = Try do
            Rails.logger.info("Persisting EmployeeModel with #{object}")
            object.save
            object.census_records.length
          end

          result.or do
            Failure(:invalid_file)
          end
        end
      end
    end
  end
end