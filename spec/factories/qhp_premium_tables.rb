# frozen_string_literal: true

FactoryBot.define do
  factory :qhp_premium_table, :class => 'Products::QhpPremiumTable' do
    rate_area_id { 'rating_area' }
    plan_id { '12345AB0111111' }
    effective_date { TimeKeeper.date_of_record.beginning_of_year }
    expiration_date { TimeKeeper.date_of_record.end_of_year }
    age_number { '20' }
    primary_enrollee { '10' }
    couple_enrollee { '20' }
    couple_enrollee_one_dependent { '25'}
    couple_enrollee_two_dependent { '30' }
    couple_enrollee_many_dependent { '40' }
    primary_enrollee_one_dependent { '15' }
    primary_enrollee_two_dependent { '20' }
    primary_enrollee_many_dependent { '30' }
  end
end
