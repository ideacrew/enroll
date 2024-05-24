# frozen_string_literal: true

RSpec.shared_context 'member_attributes_context' do
  let(:current_date) { Date.today}
  let(:dob) { current_date - 20.years }
  let(:member_hash) do
    {
      :hbx_id => "77a0be350dd1437ca5ba2259fdddb982",
      :first_name => "test_first",
      :last_name => "test_last",
      :ssn => "873672163",
      :gender => "male",
      :dob => dob,
      :is_incarcerated => true,
      :ethnicity => [],
      :tribal_id => nil,
      :tribal_state => nil,
      :tribal_name => nil,
      :tribe_codes => [],
      :no_dc_address => false,
      :is_homeless => false,
      :is_temporarily_out_of_state => false,
      :no_ssn => "0",
      :relationship => "spouse",
      :person_addresses => [
        {
          :kind => "home",
          :address_1 => "123 NE",
          :address_2 => "",
          :address_3 => "",
          :city => "was",
          :county => "",
          :state => "DC",
          :zip => "12321",
          :country_name => ""
        }
      ],
      :person_phones => [
        {
          :kind => "home",
          :country_code => "",
          :area_code => "213",
          :number => "2131322",
          :extension => "",
          :full_phone_number => "2132131322"
        },
        {
          :kind => "mobile",
          :country_code => "",
          :area_code => "213",
          :number => "2131333",
          :extension => "",
          :full_phone_number => "213213133"
        }
      ],
      :person_emails => [
        {
          :kind => "home",
          :address => "test@dtest.gov"
        }
      ],
      :skip_person_updated_event_callback => true,
      :consumer_role => {
        :skip_consumer_role_callbacks => true,
        :is_applying_coverage => true,
        :is_applicant => false,
        :citizen_status => "alien_lawfully_present",
        :immigration_documents_attributes => [
          {
            :subject => "I-94 (Arrival/Departure Record)",
            :i94_number => "65436789098",
            :expiration_date => current_date + 1.year
          }
        ]
      },
      demographics_group: {
        alive_status: {
          is_deceased: false,
          date_of_death: nil
        }
      }
    }
  end
end
