FactoryGirl.define do
  factory :hbx_profile do
    organization            { FactoryGirl.build(:organization) }
    us_state_abbreviation   "DC"    
    cms_id   "DC0"    
  end

end
