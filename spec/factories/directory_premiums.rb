FactoryBot.define do
  factory :directory_premium, :class => 'Directory::Premium' do
    hbx_id "MyString"
    hbx_plan_id "MyString"
    amount_in_cents "1111.11"
    ehb_in_cents "MyString"
    age 42
    gender 'male'
  end

end
