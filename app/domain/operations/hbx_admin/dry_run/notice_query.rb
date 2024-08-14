# frozen_string_literal: true

module Operations
  module HbxAdmin
    module DryRun
      # This Operation is responsible for building a query to fetch notice counts based on given parameters.
      class NoticeQuery
        include Dry::Monads[:do, :result]
        include L10nHelper

        # Calls the NoticeQuery operation.
        #
        # @param params [Hash] The parameters for the query.
        # @option params [Array<String>] :person_hbx_ids The person HBX IDs.
        # @option params [Date] :start_date The start date for the query.
        # @option params [Date] :end_date The end date for the query.
        # @option params [Array<String>] :title_codes The title codes for the query.
        # @return [Dry::Monads::Result] The result of the operation.
        def call(params)
          validated_params = yield validate(params)
          build_pipeline(validated_params)
        end

        private

        # Validates the input parameters.
        #
        # @param params [Hash] The parameters to validate.
        # @return [Dry::Monads::Result] The result of the validation.
        def validate(params)
          return Failure("Titles cannot be blank") if params[:title_codes].blank?
          return Failure("Person HBX IDs cannot be blank") if params[:person_hbx_ids].blank?
          return Failure("Start Date cannot be blank") if params[:start_date].blank?
          return Failure("End Date cannot be blank") if params[:end_date].blank?

          Success(params)
        end

        # Builds the MongoDB aggregation pipeline.
        #
        # @param params [Hash] The validated parameters.
        # @return [Array<Hash>] The aggregation pipeline.
        def build_pipeline(params)
          person_hbx_ids = params[:person_hbx_ids]
          start_date = params[:start_date]
          end_date = params[:end_date]
          title_codes = params[:title_codes]

          [
            { "$match" => { "hbx_id" => { '$in' => person_hbx_ids } } },
            { "$unwind" => "$documents" },
            {
              "$match" => {
                "documents.created_at" => { '$gte' => start_date, '$lte' => end_date },
                "documents.title" => { '$in' => title_codes }
              }
            },
            {
              "$group" => {
                "_id" => "$documents.title",
                "count" => { "$sum" => 1 }
              }
            },
            {
              "$project" => {
                "_id" => 0,
                "title" => "$_id",
                "count" => 1
              }
            }
          ]
        end
      end
    end
  end
end