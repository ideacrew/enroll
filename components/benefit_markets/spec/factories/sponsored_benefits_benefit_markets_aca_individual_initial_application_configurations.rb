FactoryGirl.define do
  factory :sponsored_benefits_benefit_markets_aca_individual_initial_application_configuration, class: 'SponsoredBenefits::BenefitMarkets::AcaIndividualInitialApplicationConfiguration' do

    mm_enr_due_on   15
    vr_os_window  0
    vr_due 95
    open_enrl_start_on Date.new(2017,01,31)
    open_enrl_end_on Date.new(2017,01,31)
  end
end
