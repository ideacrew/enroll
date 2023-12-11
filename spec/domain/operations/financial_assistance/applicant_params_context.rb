# frozen_string_literal: true

RSpec.shared_context 'export_applicant_attributes_context' do
  let(:current_date) { Date.today}
  let(:dob) { current_date - 20.years }
  let(:applicant_params) do
    {:_id => BSON::ObjectId('5f5ecf00d73697f046c926fe'),
     :family_id => nil,
     :person_hbx_id => '77a0be350dd1437ca5ba2259fdddb982',
     :first_name => 'test_first',
     :last_name => 'test_last',
     :gender => 'male',
     :dob => dob,
     :is_incarcerated => true,
     :ethnicity => ['White', 'Black or African American', 'Asian Indian', 'Chinese', 'Mexican', 'Mexican American'],
     :indian_tribe_member => false,
     :tribal_id => nil,
     :tribal_state => nil,
     :tribal_name => nil,
     :tribe_codes => [],
     :no_dc_address => false,
     :is_homeless => false,
     :no_ssn => "0",
     :is_temporarily_out_of_state => false,
     :citizen_status => 'alien_lawfully_present',
     :is_consumer_role => true,
     :same_with_primary => true,
     :is_applying_coverage => true,
     :vlp_subject => 'I-94 (Arrival/Departure Record)',
     :i94_number => '65436789098',
     :expiration_date => current_date + 1.year,
     :ssn => '873672163',
     :relationship => nil,
     :is_primary_applicant => false,
     :incomes => [
      {
        title: "Job Income",
        wage_type: "wages_and_salaries",
        amount: 10
      }
     ],
     :addresses =>
         [{'address_1' => '123 NE',
           'address_2' => '',
           'address_3' => '',
           'county' => '',
           'country_name' => '',
           'kind' => 'home',
           'city' => 'was',
           'state' => 'DC',
           'zip' => '12321'}],
     :emails => [{'kind' => 'home', 'address' => 'test@dtest.gov'}],
     :phones =>
         [{'kind' => 'home', 'country_code' => '', 'area_code' => '213', 'number' => '2131322', 'extension' => '', 'full_phone_number' => '2132131322'},
          {'kind' => 'mobile', 'country_code' => '', 'area_code' => '213', 'number' => '2131333', 'extension' => '', 'full_phone_number' => '213213133'}]}
  end
end
