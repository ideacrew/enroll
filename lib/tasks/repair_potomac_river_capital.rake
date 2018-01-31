namespace :update_shop do
  desc "Repair ER Potomac River Capital ER file"
  task :repair_potomac_river_capital => :environment do 

    ## DANGER -- this works for one ER, who is an initial applicant

    er_id = '562a4f4569702d0af7bc0000'
    census_employee_ids = CensusEmployee.by_employer_profile_id(er_id).map(&:id)

    puts "Clearing benefit groups for rostered EEs"
    census_employee_ids.each do |ce_id|
      census_employee = CensusEmployee.find(ce_id)
      census_employee.benefit_group_assignments = []
      census_employee.save! 
    end

    # CensusEmployee.by_employer_profile_id(er_id).each { |ce| ce.benefit_group_assignments = []; ce.save! }

    puts "Clear Employer plan years & benefit groups"

    er = EmployerProfile.find(er_id)
    er.plan_years = []

    py = er.plan_years.build(
        start_on: Date.new(2016,1,1), 
        end_on: Date.new(2016,12,31),
        open_enrollment_start_on: Date.new(2015,11,24),
        open_enrollment_end_on: Date.new(2015,12,10),
        imported_plan_year: false, 
        fte_count: 16, 
        pte_count: 0, 
        msp_count: 0
      )
    py.save

    bg = py.benefit_groups.build(
        title: "Potomac River Capital", 
        effective_on_kind: "first_of_month", 
        terminate_on_kind: "end_of_month", 
        plan_option_kind: "single_plan", 
        default: true, 
        contribution_pct_as_int: 0, 
        effective_on_offset: 0, 
        reference_plan_id:    '5618552254726535953bfc00', 
        lowest_cost_plan_id:  '5618552254726535953bfc00', 
        highest_cost_plan_id: '5618552254726535953bfc00', 
        employer_max_amt_in_cents: 0, 
        elected_plans: [Plan.find('5618552254726535953bfc00')], 
        is_congress: false,
        relationship_benefits: [
            RelationshipBenefit.new(relationship: "employee", premium_pct: 77.0, employer_max_amt: nil, offered: true),
            RelationshipBenefit.new(relationship: "spouse", premium_pct: 77.0, employer_max_amt: nil, offered: true),
            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 77.0, employer_max_amt: nil, offered: true),
            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 77.0, employer_max_amt: nil, offered: true), 
            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0.0, employer_max_amt: nil, offered: true)
          ]
      )
    bg.save
    er.save

    puts "Associate census employees with rebuilt benefit group"
    census_employee_ids.each do |ce_id|
      census_employee = CensusEmployee.find(ce_id)
      census_employee.add_benefit_group_assignment(bg, py.start_on)
      census_employee.save!
    end

    puts "Complete!"

    puts er.inspect
    puts py.inspect
    puts bg.inspect

  end
end