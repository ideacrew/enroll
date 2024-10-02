# frozen_string_literal: true

# Operations::Applications::FetchLatestDeterminedApplications.new.call({family_ids: [1, 2, 3], assistance_year: 2023})
# Operations::Applications::FetchLatestDeterminedApplications.new.call({family_ids: [1, 2, 3]})
# Operations::Applications::FetchLatestDeterminedApplications.new.call({assistance_year: 2023})
# Operations::Applications::FetchLatestDeterminedApplications.new.call({})
module FinancialAssistance
  module Operations
    module Applications
      # FetchLatestDeterminedApplications class will fetch latest determined applications
      class FetchLatestDeterminedApplications
        include Dry::Monads[:result, :do]
        include Dry::Monads::Do.for(:call)

        def call(params)
          family_ids, assistance_year = yield validate(params)
          pipeline = yield pipeline(family_ids, assistance_year)
          application_hbx_ids = yield latest_determined_application_stage(pipeline)

          Success(application_hbx_ids)
        end

        private

        def validate(params)
          family_ids = params[:family_ids]
          assistance_year = params[:assistance_year]

          Success([family_ids, assistance_year])
        end

        def latest_determined_application_stage(pipeline)
          application_hbx_ids = aggregate_collection(::FinancialAssistance::Application.collection, pipeline).collect{|b| b[:application_hbx_id]}

          if application_hbx_ids.present?
            Success(application_hbx_ids)
          else
            Failure("No determined applications found")
          end
        rescue StandardError => e
          Failure("Failed to fetch determined applications due to #{e.inspect}")
        end

        def pipeline(family_ids, assistance_year)
          query = [
            match_stage({family_ids: family_ids, assistance_year: assistance_year}),
            unwind_applicants_stage,
            match_ia_eligible_stage,
            sort_stage,
            group_stage,
            project_stage
          ]

          Success(query)
        rescue StandardError => e
          Failure("Failed to build pipeline due to #{e.inspect}")
        end

        def match_stage(params)
          family_ids = params[:family_ids]
          assistance_year = params[:assistance_year]
          match_hash = {}
          match_hash.merge!({'assistance_year' => assistance_year}) if assistance_year.present?
          match_hash.merge!({'family_id' => { '$in' => family_ids }}) if family_ids.present?
          match_hash.merge!({'aasm_state' => 'determined'})

          { '$match' => match_hash }
        end

        def unwind_applicants_stage
          { '$unwind' => '$applicants' }
        end

        def match_ia_eligible_stage
          { '$match' => { 'applicants.is_ia_eligible' => true } }
        end

        def sort_stage
          { '$sort' => { 'submitted_at' => -1 } }
        end

        def group_stage
          { '$group' => { '_id' => '$family_id', 'application_hbx_id' => { '$first' => '$hbx_id' } } }
        end

        def project_stage
          { '$project' => { 'application_hbx_id' => 1, '_id' => 0 }}
        end

        def aggregate_collection(collection, pipeline)
          collection.aggregate(pipeline, allow_disk_use: true).to_a
        end
      end
    end
  end
end