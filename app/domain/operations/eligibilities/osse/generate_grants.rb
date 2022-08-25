# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Osse
      # Build grants for the given evidence
      class GenerateGrants
        send(:include, Dry::Monads[:result, :do])

        # @param [Hash] opts Options to build grants
        # @option opts [<GlobalID>] :eligibility_gid required
        # @option opts [<String>]   :evidence_key required
        # @return [Dry::Monad] result
        def call(params)
          values   = yield validate(params)
          evidence = yield verify_evidence_satisfied?(values)
          grants   = yield create_grants(values, evidence)

          Success(grants)
        end

        private

        def validate(params)
          errors = []
          errors << 'eligibility global id missing' unless params[:eligibility_gid]
          errors << 'evidence key missing' unless params[:evidence_key]

          errors.empty? ? Success(params) : Failure(errors)
        end

        # TODO: next sprint: implement visitor pattern for checking evidence satisfied
        def verify_evidence_satisfied?(values)
          @eligibility_instance = GlobalID::Locator.locate(values[:eligibility_gid])
          evidence = @eligibility_instance.evidences.by_key(values[:evidence_key]).last
          return Success(evidence) if evidence.is_satisfied
          Failure("#{values[:evidence_key]} is not satisfield")
        end

        def create_grants(_values, evidence)
          grant_rules = fetch_grant_configurations_for(evidence)
          grants = grant_rules.collect do |rule_pair|
            grant_params = build_grant(rule_pair)
            grant_result = create_grant(grant_params)
            grant_result.success if grant_result.success?
          end.compact

          Success(grants)
        end

        def create_grant(grant_params)
          ::Operations::Eligibilities::Osse::CreateGrant.new.call(grant_params)
        end

        def fetch_grant_configurations_for(evidence)
          feature = EnrollRegistry["#{market_kind}_#{subject_name}_#{evidence.key}_#{eligibility_year}"]
          grant_keys = feature.setting(:grants_offered).item
          fetch_rules_configurations(grant_keys)
        end

        def build_grant(rule_pair)
          {
            title: rule_pair.keys[0].to_s,
            key: rule_pair.values[0].to_s,
            start_on: start_on,
             # TODO: figure out how to identify value class name
            value: build_grant_value(rule_pair)
          }
        end

        def build_grant_value(rule_pair)
          {
            title: rule_pair.keys[0].to_s,
            key: rule_pair.values[0].to_s,
            value: rule_pair.values[0].to_s
          }
        end

        def start_on
          @eligibility_instance.start_on
        end

        def eligibility_year
          start_on.year
        end

        def subject
          GlobalID::Locator.locate(@eligibility_instance.subject.key)
        end

        def subject_name
          subject&.class&.name&.demodulize&.underscore
        end

        def market_kind
          subject.market_kind
        end

        def fetch_rules_configurations(grant_keys)
          grant_keys.reduce([]) do |rule_pairs, key|
            rule_pairs << Hash[key, EnrollRegistry[key].item]
          end
        end
      end
    end
  end
end
