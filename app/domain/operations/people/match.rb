# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # This class uses different criteria for person match
    class Match
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])
      # include Ssn
      attr_reader :first_name, :last_name, :dob, :ssn, :keys_with_ssn, :keys_with_dob, :has_ssn, :has_dob

      SPECIAL_CHAR = %r([!@#$%^&*()_+{}\[\]:;'"/\\?><.,]).freeze

      # When combination of these(:first_name, :last_name, :dob, :ssn) values are sent to this operation.
      # These query criteria will be used to fetch the matching records
      ### :first_name, :last_name, :dob, :ssn is used for ME state
      ### :dob, :ssn is used for DC state
      # If no records found using ssn and dob combination
      ### :first_name, :last_name, :dob is used for both the states
      # If no records found using first_name, last_name and dob combination
      ### :first_name, :last_name is used as a generic search, but this result is not used in the current scenarios
      # @result [query_criteria, records, error], below are possible responses send back
      # [nil,records,"More than one person record found"]
      # [:name_ssn_dob, records, nil]
      # [:site_specific_policy, records, "record found with the given ssn, but state based policy to match with with name failed."]
      # [:name_dob, records, nil]
      # [:name, records, nil]
      # [nil,records, nil]
      def call(params)
        yield validate(params)
        yield fetch_config_items
        # query_params = yield query_builder(params)
        person_records = yield match_person
        yield build_result(person_records)
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
            true
          when :ssn
            @has_ssn = v&.delete('^0-9').present?
            true
          else
            v.to_s.scan(SPECIAL_CHAR).blank?
          end
        end

        if result
          @first_name = params[:first_name]
          @last_name = params[:last_name]
          @dob = params[:dob].to_date
          @ssn = params[:ssn]&.delete('^0-9')
          Success("")
        else
          Failure("invalid params")
        end
      end

      def fetch_config_items
        if EnrollRegistry[:person_match_policy].enabled?
          @keys_with_ssn = EnrollRegistry[:person_match_policy].settings(:ssn_present).item.map(&:to_sym)
          @keys_with_dob = EnrollRegistry[:person_match_policy].settings(:dob_present).item.map(&:to_sym)
          Success("")
        else
          Failure("person_match_policy is disabled")
        end
      end

      # This method queries db as per the availability of the values
      def match_person
        result = if ssn.present?
                   records = query({:dob => dob,
                                    :encrypted_ssn => Person.encrypt_ssn(ssn)}).success
                   records.count == 0 ? match_dob : [:ssn_dob, records]
                 elsif dob.present?
                   match_dob
                 else
                   [:name, query({
                                   :last_name => /^#{last_name}$/i,
                                   :first_name => /^#{first_name}$/i
                                 }).success]
                 end

        Success(result)
      end

      def match_dob
        [:name_dob, query({:dob => dob,
                           :last_name => /^#{last_name}$/i,
                           :first_name => /^#{first_name}$/i}).success]
      end

      # This method returns array of 3
      # arr[0] is query criteria used to fetch the record
      # arr[1] records in mongo criteria
      # arr[2] error if any
      #
      # @example
      #   build_result([initial_query_criteria, records])
      #   # => Object
      #
      # @return [query_criteria, records, error]
      def build_result(person_records)
        query_criteria, records = person_records

        if records.count > 1
          Success([nil,records,"More than one person record found"])
        elsif records.count == 1
          person = records.first
          case query_criteria
          when :ssn_dob
            if keys_with_ssn.all?{|k| person.send(k) == self.send(k)}
              Success([:name_ssn_dob, records, nil])
            else
              Success([:site_specific_policy,
                       records,
                       "record found with the given ssn, but state based policy to match with name failed."])
            end
          when :name_dob
            Success([:name_dob, records, nil])
          else
            Success([:name, records, nil])
          end
        else
          Success([nil,records, nil])
        end
      end

      def query(hash)
        Try() do
          Person.where(hash)
        end.to_result
      end
    end
  end
end