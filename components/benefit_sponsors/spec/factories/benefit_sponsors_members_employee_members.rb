FactoryGirl.define do
  factory :benefit_sponsors_members_employee_member, class: 'BenefitSponsors::Members::EmployeeMember' do
    last_name     "Jetson"
    first_name    "George"
    gender        :male
    dob           { Date.today - 45.years }
    date_of_hire  { Date.today - 3.years.ago }

    ssn do
      Forgery('basic').text(
        :exactly => 9,
        :allow_numeric  => true,
        :allow_lower    => false,
        :allow_upper    => false,
        :allow_special  => false
        )
    end

  end
end
