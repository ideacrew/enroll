FactoryGirl.define do
  factory(:applicant, :class => FinancialAssistance::Applicant) do
    association :application

    is_ia_eligible false
    is_medicaid_chip_eligible false
    has_fixed_address true
    tax_filer_kind "tax_filer"

    tax_household_id { 
        FactoryGirl.build(:tax_household).id 
    }

    family_member_id { 
        FactoryGirl.build(:family_member).id 
    }

  end
end
