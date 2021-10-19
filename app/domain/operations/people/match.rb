# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # this class uses different creterias for person match
    class Match
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])
      # include Ssn
      attr_reader :first_name, :last_name, :dob, :ssn, :keys_with_ssn, :keys_with_dob, :has_ssn, :has_dob

      SPECIAL_CHAR = %r([!@#$%^&*()_+{}\[\]:;'"/\\?><.,]).freeze

      def call(params)
        yield validate(params)
        yield fetch_config_items
        query_params = yield query_builder(params)
        person_records = yield match_person(query_params)
        yield build_result(person_records)
      end

      private

      def validate_dob(dob)
        if dob.nil?
          false
        else
          (dob.to_date.present? ? true : false)
        end
      end

      def validate(params)
        params.symbolize_keys!
        result = params.all? do |k, v|
          case k
          when :dob
            @has_dob = validate_dob(v)
            true
          when :ssn
            @has_ssn = v.delete('^0-9').present?
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

      # if ssn is present build query based on person_match_policy
      def query_builder(params)
        return Success({}) unless has_ssn
        return Failure({}) unless keys_with_ssn.all? {|s| params.key? s}

        Success(keys_with_ssn.each_with_object({}) do |k, collect|
          hash = case k
                 when :ssn
                   {encrypted_ssn: Person.encrypt_ssn(params[k]).gsub("\n", '')}
                 when :dob
                   {"#{k}": params[k]}
                 else
                   {"#{k}": /^#{params[k]}$/i}
                 end
          collect.merge!(hash)
        end)
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

      def match_person(_hash = {})
        result = if ssn.present?
                   records = query({:dob => dob,
                                    :encrypted_ssn => Person.encrypt_ssn(ssn).gsub("\n", '')}).success
                   records.nil? ? match_dob : [:ssn_dob, records]
                 elsif dob.present?
                   [:name_dob, query({:dob => dob,
                                      :last_name => /^#{last_name}$/i,
                                      :first_name => /^#{first_name}$/i}).success]
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

      def build_result(person_records)
        query_criteria, records = person_records

        if records.count > 1
          Success([nil,records,"More than one person record found"])
        elsif records.count == 1
          person = records.first
          case query_criteria
          when :ssn_dob
            if keys_with_ssn.all?{|k| person.send(k) == self.send(k)}
              Success([:name_ssn_dob, records])
            else
              Success([:site_specific_ssn_dob,
                       records,
                       "ssn is already affiliated with another account."])
            end
          when :name_dob
            Success([:name_dob, records])
          else
            Success([:ssn_dob, records])
          end
        else
          Success([nil,records])
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