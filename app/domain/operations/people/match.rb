# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # This class uses different criteria for person match
    class Match
      include Dry::Monads[:do, :result, :try]

      attr_reader :has_ssn, :has_dob

      SPECIAL_CHAR = %r([!@#$%^&*()_+{}\[\]:;'"/\\?><.,]).freeze

      # When combination of these(:first_name, :last_name, :dob, :ssn) values are sent to this operation.
      # These query criteria will be used to fetch the matching records
      ### :first_name, :last_name, :dob, :ssn is used for ME state
      ### :dob, :ssn is used for DC state
      # If no records found using ssn and dob combination
      ### :first_name, :last_name, :dob is used for both the states
      # If no records found using first_name, last_name and dob combination
      ### :first_name, :last_name is used as a generic search, but this result is not used in the current scenarios
      # @result [query_criteria, records], below are possible responses send back
      def call(params)
        valid_params = yield validate(params)
        configuration = yield fetch_configuration
        yield match_person(valid_params, configuration)
      end

      private

      def validate_dob(dob)
        if dob.nil?
          false
        else
          dob.to_date.present?
        end
      end

      # checks for any special characters, remove unnecessary special char and set the attrs as per values
      # @return success without any return value
      # @return failure for invalid params
      def validate(params)
        params.symbolize_keys!
        result = params.all? do |k, v|
          case k
          when :dob
            @has_dob = validate_dob(v)
          when :ssn
            @has_ssn = v&.delete('^0-9').present?
            true
          else
            # v.to_s.scan(SPECIAL_CHAR).blank?
            true
          end
        end

        if result
          Success(
            {
              first_name: params[:first_name].is_a?(String) ? /^#{Regexp.escape(params[:first_name])}$/i : params[:first_name],
              last_name: params[:last_name].is_a?(String) ? /^#{Regexp.escape(params[:last_name])}$/i : params[:last_name],
              dob: params[:dob].to_date,
              encrypted_ssn: Person.encrypt_ssn(params[:ssn]&.delete('^0-9'))
            }
          )
        else
          Failure("invalid params")
        end
      end

      def fetch_configuration
        if EnrollRegistry[:person_match_policy].enabled?
          configuration = EnrollRegistry[:person_match_policy].settings.map(&:to_h).each_with_object({}) do |s,c|
            c.merge!(s[:key] => s[:item])
          end
          Success(configuration)
        else
          Failure("person_match_policy is disabled")
        end
      end

      def match_person(params, configuration)
        records, match_criteria  = if params[:encrypted_ssn].present?
                                     match_criteria = :ssn_present
                                     output = query_by_criteria(params, configuration[match_criteria].map(&:to_sym))

                                     if output.success.empty?
                                       match_criteria = :dob_present
                                       [query_by_criteria(params, configuration[match_criteria].map(&:to_sym)), match_criteria]
                                     else
                                       [output, match_criteria]
                                     end
                                   elsif params[:dob].present?
                                     match_criteria = :dob_present
                                     [query_by_criteria(params, configuration[match_criteria].map(&:to_sym)), match_criteria]
                                   else
                                     match_criteria = :name_present
                                     [query_by_criteria(params, configuration[match_criteria].map(&:to_sym)), match_criteria]
                                   end

        Success([match_criteria, records.success])
      end

      def query_by_criteria(params, query_params)
        query_expression = params.slice(*query_params)

        Try() do
          Person.where(query_expression)
        end.to_result
      end
    end
  end
end