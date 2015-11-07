namespace :congress do
  desc "Create 2016 plan year and benefit groups for congress employers."
  task :create_2016_plan_year => :environment do
    gold_2016 = Plan.valid_shop_by_metal_level_and_year("gold", "2016").collect(&:_id)
    congress_employer_feins = []
    plan_year_attributes = [
      {
        start_on: Date.new(2016, 1, 1),
        end_on: Date.new(2016, 12, 31),
        open_enrollment_start_on: Date.new(2016, 11, 9),
        open_enrollment_end_on: Date.new(2016, 12, 13),
        benefit_group_attributes: {
          title: "2016 Benefit Group",
          contribution_pct_as_int: 75,
          employee_max_amt_in_cents: 462_30,
          first_dependent_max_amt_in_cents: 998_88,
          over_one_dependents_max_amt_in_cents: 1058_42,
          reference_plan_id: gold_2016.first,
          elected_plan_ids: gold_2016
        }
      }
    ]
    relationship_benefit_attributes = [
      {
        relationship: :employee,
        premium_pct: 75,
        offered: true
      },
      {
        relationship: :spouse,
        premium_pct: 75,
        offered: true
      },
      {
        relationship: :domestic_partner,
        premium_pct: 0,
        offered: false
      },
      {
        relationship: :child_under_26,
        premium_pct: 75,
        offered: true
      },
      {
        relationship: :child_26_and_over,
        premium_pct: 75,
        offered: false
      }
    ]

    congress_employer_feins.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)
      plan_year = nil
      if employer_profile.nil?
        puts "Unable to find employer profile for fein #{fein}"
      else
        plan_year_attributes.each do |plan_year_attribs|
          plan_year = PlanYear.new(plan_year_attribs.except(:benefit_group_attributes))
          employer_profile.plan_years = [plan_year]
          benefit_group = BenefitGroupCongress.new(plan_year_attribs[:benefit_group_attributes])
          benefit_group.relationship_benefits =
            relationship_benefit_attributes.collect do |relationship_benefit_attribs|
              RelationshipBenefit.new(relationship_benefit_attribs)
            end
          plan_year.benefit_groups = [benefit_group]
        end
      end
      if plan_year.valid? && plan_year.save
        puts "Successfully created plan year #{plan_year.start_on.year} for employer #{fein}."
      else
        puts plan_year.errors.full_messages.inspect
        puts "Error creating plan year #{plan_year.start_on.year} for employer #{fein}."
      end
    end
  end
end
