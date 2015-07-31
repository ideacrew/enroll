FactoryGirl.define do
  factory :hbx_profile do
    organization            { FactoryGirl.build(:organization) }
  end

end
