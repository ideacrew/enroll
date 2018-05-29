FactoryGirl.define do
  factory :benefit_sponsors_accounts_broker_agency_account, class: 'BenefitSponsors::Accounts::BrokerAgencyAccount' do

    start_on                TimeKeeper.date_of_record
    broker_agency_profile   { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile)}
    writing_agent           { FactoryGirl.create(:broker_role)}

  end
end
