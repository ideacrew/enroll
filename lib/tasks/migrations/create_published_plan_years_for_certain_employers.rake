# This rake task is used to create plan year for expection case with plan plan year info
# RAILS_ENV=production bundle exec rake migrations:create_published_plan_year

namespace :migrations do

  desc "create plan year with info"

  task :create_published_plan_year => :environment do

    organization = Organization.where(fein: /520858689/).last
    employer_profile = organization.employer_profile
    if organization.present?
      reference_plan = Plan.where(active_year: 2016, hios_id: /78079DC0220024-01/).last
      elected_plans = Plan.valid_shop_health_plans("carrier", "53e67210eb899a4603000004",2016).map(&:id)

      dental_reference_plan = Plan.where(active_year: 2016, hios_id: /78079DC0340001/).last

      dental_elected_plans = Plan.by_active_year(2016).shop_market.dental_coverage.by_carrier_profile(dental_reference_plan.carrier_profile).map(&:id)



      plan_year = employer_profile.plan_years.build(
          start_on: Date.new(2016,07,1),
          end_on: Date.new(2017,06,30),
          open_enrollment_start_on: Date.new(2016,06,03),
          open_enrollment_end_on: Date.new(2016,06,13),
          fte_count: 02
      )

      benefit_group = plan_year.benefit_groups.build(
          title: "Standard #{plan_year.start_on.year}",
          description: "",

          # health
          plan_option_kind: "single_carrier",
          carrier_for_elected_plan: "53e67210eb899a4603000004",
          reference_plan_id: reference_plan.id,
          elected_plan_ids: elected_plans,

          # dental
          dental_reference_plan_id: dental_reference_plan.id,
          elected_dental_plan_ids: dental_elected_plans,
          dental_plan_option_kind: "single_carrier",
          carrier_for_elected_dental_plan:'53e67210eb899a4603000004',

          effective_on_offset: 60,
          effective_on_kind: "first_of_month",
          terminate_on_kind: "end_of_month",
          is_congress: false

      )

      # health
      rbs = benefit_group.build_relationship_benefits
      rbs.each do |rb|
        if rb.relationship == "child_26_and_over"

        else
          rb.premium_pct = 100.00
        end
      end

      # dental
      dental_rbs = benefit_group.build_dental_relationship_benefits
      dental_rbs.each do |rb|
        if rb.relationship == "child_26_and_over"
          rb.offered = false
        else
          rb.premium_pct = 100.00
        end
      end

      plan_year.save!

      # assign benefit group assignments if any census employee present
      ces = employer_profile.census_employees
      ces.each do |census_employee|
        census_employee.benefit_group_assignments << BenefitGroupAssignment.new({benefit_group_id: benefit_group.id , start_on: plan_year.start_on})
        # fixing existing employee enrollments
        if census_employee.employee_role.present?
          census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.each do |hbx|
            if hbx.effective_on.strftime('%Y-%m-%d') == "2016-07-01"
              hbx.update_attributes(benefit_group_id:benefit_group.id, benefit_group_assignment_id: census_employee.benefit_group_assignments.where(benefit_group_id:benefit_group.id).first.id)
            end
          end
        end
      end

      plan_year.force_publish!  # enrolling
      plan_year.activate! if plan_year.can_be_activated?  # to active state
    end

  end
end