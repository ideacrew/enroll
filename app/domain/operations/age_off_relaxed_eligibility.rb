# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  class AgeOffRelaxedEligibility
    include Config::SiteConcern
    include Dry::Monads[:result, :do]

    def call(effective_on:, dob:, market_key:, relationship_kind:)
      _values        = yield validate(effective_on, dob, market_key, relationship_kind)
      age_off_period = yield fetch_age_off_period(market_key)
      cut_off_age    = yield fetch_cut_off_age(market_key)
      _relation      = yield validate_relationship(market_key, relationship_kind)
      result         = yield is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, dob)

      Success(result)
    end

    private

    def validate(effective_on, dob, market_key, relationship_kind)
      market_keys = [:aca_shop_dependent_age_off, :aca_fehb_dependent_age_off, :aca_individual_dependent_age_off]
      return Failure('Invalid effective_on') unless effective_on.is_a?(Date)
      return Failure('Invalid dob') unless effective_on.is_a?(Date)
      return Failure('Invalid market_key') unless market_keys.include?(market_key)

      Success('Valid params')
    end

    def fetch_age_off_period(market_key)
      Success(EnrollRegistry[market_key].setting(:period).item)
    end

    def fetch_cut_off_age(market_key)
      Success(EnrollRegistry[market_key].setting(:cut_off_age).item)
    end

    def validate_relationship(market_key, relationship_kind)
      value = EnrollRegistry[market_key].setting(:relationship_kinds).item.include?(relationship_kind)
      value ? Success('Valid relationship kind') : Failure('Invalid relationship kind')
    end

    def age_on(date, dob)
      age = date.year - dob.year
      if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
        age - 1
      else
        age
      end
    end

    def is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, dob)
      comparision_date = (age_off_period == :annual) ? effective_on.beginning_of_year : effective_on.beginning_of_month
      age = age_on(comparision_date, dob)
      true_or_false = (age < cut_off_age) || (age == cut_off_age && dob.month >= comparision_date.month)
      true_or_false ? Success('Eligible') : Failure('Not eligible')
    end
  end
end
