FactoryGirl.define do
  factory(:generative_organization, {class: Organization}) do
    legal_name  { Forgery('name').company_name + " " + Forgery('name').industry }
    dba { "A string" }
    fein { Forgery(:basic).number({:min => 0, :max => 999999999}).to_s.rjust(9, '0') }
    home_page { "http://" + Forgery(:internet).domain_name }
    updated_at { DateTime.new }
    created_at { DateTime.new }
    is_active { Forgery('basic').boolean }
  end

  factory(:generative_carrier_profile, {class: CarrierProfile}) do
    organization { 
      FactoryGirl.build_stubbed :generative_organization
    }
  end

  factory(:generative_reference_plan, {class: Plan}) do
    active_year 2015
    hios_id "JDFLKJELKFJKLDJFIODFIE-01"
    coverage_kind { 
      pick_list = Plan::COVERAGE_KINDS
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    metal_level { 
      pick_list = Plan::METAL_LEVEL_KINDS
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    carrier_profile {
      FactoryGirl.build_stubbed :generative_carrier_profile
    }
  end

  factory(:generative_relationship_benefit, {class: RelationshipBenefit}) do
    transient do
      rel_kind ""
    end
    relationship { rel_kind }
    premium_pct { Random.rand * 100.00 }
    offered { Forgery('basic').boolean }
  end

  factory(:generative_benefit_group, {class: BenefitGroup}) do
    reference_plan { FactoryGirl.build_stubbed :generative_reference_plan }
    relationship_benefits {
        (BenefitGroup::PERSONAL_RELATIONSHIP_KINDS.map do |rk|
          FactoryGirl.build_stubbed(:generative_relationship_benefit, :rel_kind => rk)
        end)
    }
  end

  factory(:generative_plan_year, {class: PlanYear}) do
    open_enrollment_start_on Date.today
    open_enrollment_end_on Date.today
    start_on Date.today
    end_on Date.today
    benefit_groups { 
      example_count = Random.rand(4)
      (0..example_count).to_a.map do |e|
        FactoryGirl.build_stubbed :generative_benefit_group
      end
    }
  end

  factory(:generative_employer_profile, {class: EmployerProfile}) do
    entity_kind { 
      pick_list = Organization::ENTITY_KINDS
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    organization { FactoryGirl.build_stubbed :generative_organization }
    plan_years { 
      example_count = Random.rand(6)
      (0..example_count).to_a.map do |e|
        FactoryGirl.build_stubbed :generative_plan_year
      end
    }
  end
end
