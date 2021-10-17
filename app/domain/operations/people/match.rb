# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # this class uses different creterias for person match
    class Match
      include Dry::Monads[:result, :do]
      # include Ssn
      attr_reader :first_name, :last_name, :dob, :ssn, :keys_with_ssn, :keys_with_dob, :has_ssn, :has_dob

      SPECIAL_CHAR = %r([!@#$%^&*()_+{}\[\]:;'"\/\\?><.,]).freeze

      def call(params)
        yield validate(params)
        yield fetch_config_items
        query_params = yield query_builder(params)
        result = yield match_person(query_params)

        Success(result)
      end

      private

      def validate_dob(dob)
        result = dob.nil? ? false : Date.strptime(v, "%Y-%m-%d") rescue nil
        result.nil? ? false : result
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
          @dob = params[:dob]
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

      def match_person(query_params = {})
        result = if ssn.present?
                   Person.where(query_params).first || match_ssn_employer_person
                 else
                   Person.where({:dob => dob,
                                 :last_name => /^#{last_name}$/i,
                                 :first_name => /^#{first_name}$/i
                                }).first
                 end
        Success(result)
      end

      def match_ssn_employer_person
        existing_person = Person.where({:dob => dob,
                                        :last_name => /^#{last_name}$/i,
                                        :first_name => /^#{first_name}$/i
                                       }).first
        return existing_person if existing_person.present? && existing_person.employer_staff_roles?
        nil
      end
    end
  end
end
