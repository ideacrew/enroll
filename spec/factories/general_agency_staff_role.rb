FactoryBot.define do
  factory :general_agency_staff_role do
    person { FactoryBot.create(:person) }
    npn do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 8)
    end
    general_agency_profile_id { FactoryBot.create(:general_agency_profile).id }
  end
end
