module BenefitSponsors
  module SponsoredBenefits
    class CensusEmployeeCoverageCostEstimator
      EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled) do
        def is_disabled?
          is_disabled
        end

        def is_primary_member?
          is_primary_member
        end
      end

      class CensusEmployeeMemberGroupMapper
        include Enumerable

        attr_reader :reference_product
        attr_reader :coverage_start

        def initialize(r_product, c_start)
          @reference_product = r_product
          @coverage_start = c_start
        end

        def each
          criteria.each do |ce|
            yield rosterize_census_employee(ce)
          end
        end

        def map_ce_relationship(rel)
          {
            "spouse" => "spouse",
            "domestic_partner" => "domestic partner",
            "child_under_26" => "child",
            "disabled_child_26_and_over" => "disabled child"
          }[rel]
        end

        def map_ce_disabled(rel)
          rel == "disabled_child_26_and_over"
        end

        def rosterize_census_employee(census_employee)
          member_entries = [EnrollmentMemberAdapter.new(
            census_employee.id,
            census_employee.dob,
            "self",
            true,
            false
          )]
          member_enrollments = [::BenefitSponsors::Enrollments::MemberEnrollment.new({
            member_id: census_employee.id
          })]
          dependent_entries = []
          census_employee.census_dependents.each do |cm|
            if cm.dob <= coverage_start
              member_entries << EnrollmentMemberAdapter.new(
                cm.id,
                cm.dob,
                map_ce_relationship(ce.relationship),
                false,
                map_ce_disabled(ce.relationship)
              )
              member_enrollments << ::BenefitSponsors::Enrollments::MemberEnrollment.new({
                member_id: census_employee.id
              })
            end
          end
          group_enrollment = ::BenefitSponsors::Enrollments::GroupEnrollment.new(
            {
              product: reference_product,
              rate_schedule_date: nil,
              coverage_start: coverage_start,
              member_enrollments: member_enrollments
            })
          ::BenefitSponsors::Members::MemberGroup.new(
            member_enrollments,
            {group_enrollment: group_enrollment}
          )
        end

        attr_reader :benefit_sponsorship, :coverage_start

        def initialize(b_sponsorship, c_start)
          @benefit_sponsorship = b_sponsorship
          @coverage_start = c_start
        end

        def calculate(sponsored_benefit, pricing_model, contribution_model, reference_product, p_package)
          p_calculator = pricing_model.pricing_calculator
          c_calculator = contribution_model.contribution_calculator
          p_determination_builder = p_calculator.pricing_determination_builder
          cm_builder = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
          sponsor_contribution = cm_builder.build_sponsor_contribution(p_package)
          sponsor_contribution.sponsored_benefit = sponsored_benefit
          roster_eligibility_optimizer = RosterEligibilityOptimizer.new(contribution_model)
          price = 0.00
          contribution = 0.00
          if employees_enrolling.count < 1
            [sponsor_contribution, price, contribution]
          end
          if p_determination_builder
            precalculate_costs(
              sponsored_benefit,
              pricing_model,
              contribution_model,
              reference_product,
              sponsor_contribution,
              p_calculator,
              c_calculator,
              roster_eligibility_optimizer,
              p_determination_builder
            )
          end
          price, contribution = calculate_normal_costs(
            pricing_model,
            contribution_model,
            reference_product,
            sponsor_contribution,
            p_calculator,
            c_calculator,
            roster_eligibility_optimizer
          )
          [sponsor_contribution, price, contribution]
        end

        def precalculate_costs(
          sponsored_benefit,
          pricing_model,
          contribution_model,
          reference_product,
          sponsor_contribution,
          p_calculator,
          c_calculator,
          roster_eligibility_optimizer,
          p_determination_builder_klass
        )
          p_determination_builder = p_determination_builder_klass.new
          group_size = calculate_group_size
          participation = calculate_participation_percent
          sic_code = sponsor_contribution.sic_code
          enrolling_employees = employees_enrolling
          group_mapper = CensusEmployeeMemberGroupMapper.new(enrolling_employees, reference_product, coverage_start)
          mapped_eligible_roster = group_mapper.lazy.map do |e_roster_entry|
            roster_eligibility_optimizer.calculate_optimal_group_for(contribution_model, e_roster_entry, sponsor_contribution)
          end
          p_determination_builder.create_pricing_determination(sponsored_benefit, reference_product, pricing_model, mapped_eligible_roster, group_size, participation, sic_code)
        end

        def calculate_normal_costs(
          pricing_model,
          contribution_model,
          reference_product,
          sponsor_contribution,
          p_calculator,
          c_calculator,
          roster_eligibility_optimizer
        )
          price_total = 0.00
          contribution_total = 0.00
          enrolling_employees = employees_enrolling
          group_mapper = CensusEmployeeMemberGroupMapper.new(enrolling_employees, reference_product, coverage_start)
          group_mapper.each do |ce_roster|
            roster_group = roster_eligibility_optimizer.calculate_optimal_group_for(contribution_model, e_roster_entry, sponsor_contribution)
            price_group = p_calculator.calculate_price_for(pricing_model, roster_group, sponsor_contribution)
            contribution_group = c_calculator.calculate_contribution_for(contribution_model, price_group, sponsor_contribution)
            price_total = price_total + contribution_group.group_enrollment.product_cost_total
            contribution_total = contribution_total + contribution_group.group_enrollment.sponsor_contribution_total
          end
          [price_total, contribution_total]
        end

        def eligible_employee_criteria
          ::CensusEmployee.where(
            :benefit_sponsorship_id => benefit_sposorship.id,
            :hired_on => {"$lte" => coverage_start},
            "$or" => [
              { "terminated_on" => nil },
              { "terminated_on" => { "$gt" => coverage_start } }
            ]
          )
        end

        def eligible_employee_count
          @eligible_employee_count ||= eligible_employee_criteria.count
        end

        def employees_enrolling
          eligible_employee_criteria.where({expected_selection: "enroll"})
        end

        def calculate_group_size
          employees_enrolling.count
        end

        def calculate_participation_percent
          enrolling_count = calculate_group_size
          return 0.0 if enrolling_count < 1
          (enrolling_count.to_f / eligible_employee_count) * 100.0
        end
      end
    end
  end
end
