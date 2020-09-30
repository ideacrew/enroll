# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  class AgeOffRelaxedEligibility
    include Config::SiteConcern
    send(:include, Dry::Monads[:result, :do])

    def call(coverage_start:, person:, market_key:, relationship_kind:)
      age_off_period = yield fetch_age_off_period(market_key)
      cut_off_age = yield fetch_cut_off_age(market_key)
      _relation = yield validate_relationship(market_key, relationship_kind)
      result = yield is_person_eligible_on_enrollment?(age_off_period, cut_off_age, coverage_start, person)
      Success(result)
    end

    private

    def fetch_age_off_period(market_key)
      Success(EnrollRegistry[market_key].setting(:period).item)
    end

    def fetch_cut_off_age(market_key)
      Success(EnrollRegistry[market_key].setting(:cut_off_age).item)
    end

    def validate_relationship(market_key, relationship_kind)
      value = EnrollRegistry[market_key].setting(:relationship_kinds).item.include?(relationship_kind)
      value ? Success(true) : Failure('relationship failed')
    end

    def is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, person)
      true_or_false = if age_off_period == :annual
                        person.age_on(effective_on.beginning_of_year - 1.day) <= cut_off_age
                      elsif age_off_period == :monthly
                        person.age_on(effective_on.beginning_of_month - 1.day) <= cut_off_age
                      end
      true_or_false ? Success(true) : Failure('Not eligible')
    end
  end
end

