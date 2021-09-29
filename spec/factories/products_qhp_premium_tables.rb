# frozen_string_literal: true

FactoryBot.define do
  factory :products_qhp_premium_tables, :class => 'Products::QhpPremiumTable' do

    primary_enrollee { 100.00 }
    couple_enrollee { 200.00 }
    couple_enrollee_one_dependent { 300.00 }
    couple_enrollee_two_dependent { 400.00 }
    couple_enrollee_many_dependent { 500.00 }
    primary_enrollee_one_dependent { 200.00 }
    primary_enrollee_two_dependent { 300.00 }
    primary_enrollee_many_dependent { 400.00 }
  end
end
