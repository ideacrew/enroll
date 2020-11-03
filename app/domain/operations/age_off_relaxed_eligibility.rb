# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  class AgeOffRelaxedEligibility
    include Config::SiteConcern
    include Dry::Monads[:result, :do]

    def call(effective_on:, dob:, market_key:, relationship_kind:)
      age_off_period = yield fetch_age_off_period(market_key)
      cut_off_age = yield fetch_cut_off_age(market_key)
      _relation = yield validate_relationship(market_key, relationship_kind)
      result = yield is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, dob)

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
      true_or_false = if age_off_period == :annual
                        age_on(effective_on.beginning_of_year, dob) <= cut_off_age
                      elsif age_off_period == :monthly
                        effective_on_start_of_month = effective_on.beginning_of_month
                        age = age_on(effective_on_start_of_month, dob)
                        (age < cut_off_age) || (age == cut_off_age && dob.month >= effective_on_start_of_month.month)
                      end
      true_or_false ? Success('Eligible') : Failure('Not eligible')
    end
  end
end
