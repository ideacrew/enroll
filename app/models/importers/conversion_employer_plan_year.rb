module Importers
  class ConversionEmployerPlanYear
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :fein, :plan_selection

    attr_accessor :action,
      :enrolled_employee_count,
      :new_coverage_policy,
      :carrier,
      :default_plan_year_start,
      :most_common_hios_id,
      :single_plan_hios_id

    validates_length_of :fein, is: 9

    validate :validate_fein
    validate :validate_carrier

    validates_presence_of :carrier, :allow_blank => false
    validates_presence_of :plan_selection, :allow_blank => false
    validates_numericality_of :enrolled_employee_count, :allow_blank => false

    attr_reader :warnings

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    include ValueParsers::SsnParser.on(:fein)

    def plan_selection=(val)
      @plan_selection = (val.to_s =~ /single plan/i) ? "single_plan" : "single_carrier"
    end

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      else
        if found_employer.plan_years.any? && (found_employer.profile_source == "conversion")
          errors.add(:fein, "employer already has conversion plan years")
        end
      end
    end

    def validate_carrier
      return true if fein.blank?
      found_carrier = find_carrier
      if found_carrier.nil?
        errors.add(:carrier, "does not exist with name #{carrier}")
      end
    end

    def find_employer
      org = Organization.where(:fein => fein).first
      return nil unless org
      org.employer_profile
    end

    def find_carrier
      org = Organization.where("carrier_profile.abbrev" => carrier).first
      return nil unless org
      org.carrier_profile
    end

    def map_plan_year
      employer = find_employer
      found_carrier = find_carrier
      plan_year_attrs = Factories::PlanYearFactory.default_dates_for_coverage_starting_on(default_plan_year_start)
      plan_year_attrs[:fte_count] = enrolled_employee_count
      plan_year_attrs[:employer_profile] = employer
      plan_year_attrs[:benefit_groups] = [map_benefit_group(found_carrier)]
#      plan_year_attrs[:imported_plan_year] = true
      plan_year_attrs[:aasm_state] = "active"
      PlanYear.new(plan_year_attrs)
    end

    def select_most_common_plan(available_plans, most_expensive_plan)
        if !most_common_hios_id.blank?
          found_single_plan = available_plans.detect { |pl| pl.hios_id == most_common_hios_id.strip }
          return found_single_plan if found_single_plan
          warnings.add(:most_common_hios_id, "hios id #{most_common_hios_id.strip} not found for most common plan, defaulting to most expensive plan")
        else
          warnings.add(:most_common_hios_id, "no most common hios id specified, defaulting to most expensive plan")
        end
        most_expensive_plan
    end

    def select_reference_plan(available_plans)
      plans_by_cost = available_plans.sort_by { |plan| plan.premium_tables.first.cost }
      most_expensive_plan = plans_by_cost.last
      if (plan_selection == "single_plan")
        if !single_plan_hios_id.blank?
          found_single_plan = available_plans.detect { |pl| pl.hios_id == single_plan_hios_id.strip }
          return found_single_plan if found_single_plan
          warnings.add(:single_plan_hios_id, "hios id #{single_plan_hios_id.strip} not found for single plan benefit group defaulting to most common plan")
        else
          warnings.add(:single_plan_hios_id, "no hios id specified for single plan benefit group, defaulting to most common plan")
        end
      end
      select_most_common_plan(available_plans, most_expensive_plan)
    end

    def map_benefit_group(found_carrier)
      available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, default_plan_year_start.year)
      reference_plan = select_reference_plan(available_plans)
      elected_plan_ids = (plan_selection == "single_plan") ? [reference_plan.id] : available_plans.map(&:id)
      BenefitGroup.new({
        :title => "Standard",
        :plan_option_kind => plan_selection,
        :relationship_benefits => map_relationship_benefits,
        :reference_plan_id => reference_plan.id,
        :elected_plan_ids => elected_plan_ids
      })
    end

    def map_relationship_benefits
      BenefitGroup::PERSONAL_RELATIONSHIP_KINDS.map do |rel|
        RelationshipBenefit.new({
          :relationship => rel,
          :offered => true,
          :premium_pct => 50.00
        })
      end
    end

    def save
      return false unless valid?
      record = map_plan_year
      save_result = record.save
      propagate_errors(record)
      if save_result
        employer = find_employer
        begin
          employer.update_attributes!(:aasm_state => "enrolled", :profile_source => "conversion")
          map_employees_to_benefit_groups(employer, record)
        rescue Exception => e
          raise "\n#{employer.fein} - #{employer.legal_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
        end
      end
      return save_result
    end

    def map_employees_to_benefit_groups(employer, plan_year)
      bg = plan_year.benefit_groups.first
      employer.census_employees.non_terminated.each do |ce|
        ce.add_benefit_group_assignment(bg)
        ce.save!
      end
    end

    def propagate_errors(plan_year)
      plan_year.errors.each do |attr, err|
        errors.add("plan_year_" + attr.to_s, err)
      end
      plan_year.benefit_groups.first.errors.each do |attr, err|
        errors.add("plan_year_benefit_group_" + attr.to_s, err)
      end
    end
  end
end
