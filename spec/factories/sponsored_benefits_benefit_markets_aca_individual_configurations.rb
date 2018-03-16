FactoryGirl.define do
  factory :sponsored_benefits_benefit_markets_aca_individual_configuration, class: 'SponsoredBenefits::BenefitMarkets::AcaIndividualConfiguration' do

    mm_enr_due_on   15
    vr_os_window  0
    vr_due 95
    open_enrl_start_on Date.new(2017,01,31)
    open_enrl_end_on Date.new(2017,01,31)

    trait :with_initial_configuration do
      after :build do |individual_configuration, evaluator|
        build(:sponsored_benefits_benefit_markets_aca_initial_individual_configuration, pub_due_dom: 5, erlst_strt_prior_eff_months: -3, appeal_per_aft_app_denial_dys: 30, quiet_per_end: 28, inelig_per_aft_app_denial_dys: 90 )
      end
    end
  end
end
