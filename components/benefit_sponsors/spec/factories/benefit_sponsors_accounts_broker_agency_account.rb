FactoryGirl.define do
  factory :benefit_sponsors_accounts_broker_agency_account, class: 'BenefitSponsors::Accounts::BrokerAgencyAccount' do

    start_on                TimeKeeper.date_of_record
    broker_agency_profile   { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile)}
    writing_agent           { FactoryGirl.create(:broker_role)}
    benefit_sponsorship     { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile)}

  end
end
