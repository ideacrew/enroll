FactoryBot.define do
  factory :invitation do
    aasm_state { 'active' }
    invitation_email { Forgery(:internet).email_address }
    source_kind { %w(census_employee, broker_role, broker_agency_staff_role, employer_staff_role, assister_role, csr_role, hbx_staff_role, general_agency_staff_role).sample }
    role do
      { "census_employee" => "employee_role",
        "broker_role" => "broker_role",
        "broker_agency_staff_role" => "broker_agency_staff_role",
        "employer_staff_role" => "employer_staff_role",
        "assister_role" => "assister_role",
        "csr_role" => "csr_role",
        "hbx_staff_role" => "hbx_staff_role",
        "general_agency_staff_role" => "general_agency_staff_role" }[source_kind]
    end

    source_id { FactoryBot.create(source_kind.to_sym).id.to_s }
  end

  trait :census_employee do
    source_kind { 'census_employee' }
    role { 'employee_role' }
  end

  trait :broker_role do
    source_kind { 'broker_role' }
    role { 'broker_role' }
  end

  trait :broker_agency_staff_role do
    source_kind { 'broker_agency_staff_role' }
    role { 'broker_agency_staff_role' }
  end

  trait :employer_staff_role do
    source_kind { 'employer_staff_role' }
    role { 'employer_staff_role' }
  end

  trait :assister_role do
    source_kind { 'assister_role' }
    role { 'assister_role' }
  end

  trait :csr_role do
    source_kind { 'csr_role' }
    role { 'csr_role' }
  end

  trait :hbx_staff_role do
    source_kind { 'hbx_staff_role' }
    role { 'hbx_staff_role' }
  end

  trait :general_agency_staff_role do
    source_kind { 'general_agency_staff_role' }
    role { 'general_agency_staff_role' }
  end
end
