class EmployerAppMigration

    def self.reference_plan_id_for(hios_id, active_year = 2015)
      Plan.where(hios_id: hios_id, active_year: active_year).first.id
    end

    def self.census_employees(employer_profile)
      CensusEmployee.by_employer_profile_id(employer_profile.id)
    end

    def self.applications
      [

        { legal_name: "Chapman Associates",
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,1,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_plan",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 0,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("78079DC0230008-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 50, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 0, offered: false),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 0, offered: false),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 0, offered: false),
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }

          },

        { legal_name: "network rail", 
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,4,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_carrier",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 0,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("86052DC0520006-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 100, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 0, offered: true) ,
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }
          },

        { legal_name: "Bergmann Zwerdling Direct",
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,5,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_carrier",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 0,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("86052DC0440009-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 100, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 100, offered: true),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 100, offered: true),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 100, offered: true) ,
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }

          },

        { legal_name: "bellrose glass",
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,4,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_carrier",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 60,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("86052DC0540004-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 75, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 0, offered: true) ,
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }

          },

        { legal_name: "Intelligence Declassified",
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,3,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_carrier",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 0,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("86052DC0500007-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 100, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 0, offered: true) ,
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }

          },

        { legal_name: "mba consulting",
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,1,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_carrier",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 0,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("78079DC0300005-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 100, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 50, offered: true),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 50, offered: true),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 50, offered: true) ,
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }

          },

        # { legal_name: "Tonia Woods",
        { legal_name: "anytime canine",
          plan_year: {
              imported_plan_year: true, 
              start_on: Date.new(2015,1,1), 
              benefit_groups: [
                  BenefitGroup.new(
                      title: "Employee Benefits",
                      plan_option_kind: "single_carrier",
                      effective_on_kind: "date_of_hire",
                      effective_on_offset: 30,
                      default: true,
                      reference_plan_id: EmployerAppMigration.reference_plan_id_for("94506DC0350004-01"),
                      relationship_benefits: [
                            RelationshipBenefit.new(relationship: "employee", premium_pct: 50, offered: true),
                            RelationshipBenefit.new(relationship: "spouse", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "domestic_partner", premium_pct: 0, offered: true),
                            RelationshipBenefit.new(relationship: "child_under_26", premium_pct: 0, offered: true) ,
                            RelationshipBenefit.new(relationship: "child_26_and_over", premium_pct: 0, offered: false)
                          ]
                      )
                  ]
              }

          },
      ]

    end
end


namespace :migrations do
  desc "Set Employer's initial application to correct state for employee enrollment"
  task :publish_er_initial_app => :environment do

    changed_count = 0
    renewed_count = 0

    EmployerAppMigration.applications.each do |application|

      employer_match = application[:legal_name]
      organization = Organization.where(legal_name: /#{employer_match}/i).entries

      if organization.size == 1
        employer_profile = organization.first.employer_profile
        puts "processing employer: #{employer_profile.legal_name}"
        
        initial_plan_year = employer_profile.plan_years.detect { |py| py.start_on == application[:plan_year][:start_on] }

        if initial_plan_year.blank?
          plan_year = PlanYear.new(application[:plan_year])
          plan_year.employer_profile = employer_profile
          plan_year.fte_count = EmployerAppMigration.census_employees(employer_profile).size
          plan_year.end_on = (plan_year.start_on + 1.year) - 1.day

          if plan_year.start_on == Date.new(2015,1,1)
            plan_year.open_enrollment_start_on = Date.new(2015,12,1)
            plan_year.open_enrollment_end_on = Date.new(2015,12,10)
          else
            plan_year.open_enrollment_start_on = (plan_year.start_on - 1.day).beginning_of_month
            plan_year.open_enrollment_end_on = plan_year.open_enrollment_start_on + 9.days
          end

          plan_year.benefit_groups.each do |benefit_group| 
            # benefit_group.build_relationship_benefits
            benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
          end

          plan_year.benefit_groups.first.save!
          plan_year.aasm_state = "published" #! if plan_year.may_publish?
          plan_year.save!
          employer_profile.save!
        else
          puts "  plan year #{initial_plan_year.start_on} already exists for #{employer_profile.legal_name}"
        end

        plan_year ||= initial_plan_year

        EmployerAppMigration.census_employees(employer_profile).each do |ee|
          if ee.active_benefit_group_assignment.blank?
            puts "  assigning benefit group for employee: #{ee.full_name}"
            ee.add_benefit_group_assignment(plan_year.benefit_groups.first, plan_year.start_on)
            ee.save!
          end
        end

        if plan_year.start_on == Date.new(2015,1,1)
          puts "renewing employer plan year: #{employer_profile.legal_name}"
          # renew plan year
          if employer_profile.plan_years.detect { |py| py.is_renewing? }.blank?
            factory = Factories::PlanYearRenewalFactory.new(employer_profile: employer_profile, is_congress: false)
            factory.renew
            renewed_count += 1
          else
            puts "  plan year #{plan_year.start_on} already exists for #{employer_profile.legal_name}"
          end
        end

        changed_count += 1
      else
        if organization.size == 0
          puts "error: no employers matched for #{employer_match}"
        else
          puts "error: multiple employers matched for #{employer_match}"
        end
      end
    end

    puts "*** updated #{changed_count} employer applications and renewed #{renewed_count} applications ***"

  end
end