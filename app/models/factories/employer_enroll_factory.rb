module Factories
  class EmployerEnrollFactory

    attr_accessor :employer_profile, :date

    def initialize
      @logger = Logger.new("#{Rails.root}/log/employer_enroll_factory_logfile.log")
    end

    def begin
      @logger.debug "Processing #{employer_profile.legal_name}"
      published_plan_years = @employer_profile.plan_years.published_or_renewing_published.select do |plan_year|
        (plan_year.start_on..plan_year.end_on).cover?(@date || TimeKeeper.date_of_record)
      end

      if published_plan_years.size > 1
        @logger.debug "Found more than 1 published plan year for #{employer_profile.legal_name}"
        return
      end

      if published_plan_years.empty?
        @logger.debug "Published plan year missing for #{employer_profile.legal_name}."
        return
      end

      current_plan_year = published_plan_years.first

      census_employee_factory = Factories::CensusEmployeeFactory.new
      census_employee_factory.plan_year = current_plan_year

      @employer_profile.census_employees.non_terminated.each do |census_employee|
        begin
          census_employee_factory.census_employee = census_employee
          census_employee_factory.begin_coverage

        rescue Exception => e
          @logger.debug "Exception #{e.inspect} occured for #{census_employee.full_name}"
        end
      end

      current_plan_year.activate! if current_plan_year.may_activate?

      if @employer_profile.may_enroll_employer?
        @employer_profile.enroll_employer!
      elsif @employer_profile.may_force_enroll?
        @employer_profile.force_enroll!
      end

      create_active_benefit_group_assignments(current_plan_year.benefit_groups)
    end

    def end
      expiring_plan_years = @employer_profile.plan_years.published_or_renewing_published.where(:"end_on".lt => (@date || TimeKeeper.date_of_record))
      expiring_plan_years.each do |expiring_plan_year|
        census_employee_factory = Factories::CensusEmployeeFactory.new
        census_employee_factory.plan_year = expiring_plan_year

        @employer_profile.census_employees.non_terminated.each do |census_employee|
          begin
            census_employee_factory.census_employee = census_employee
            census_employee_factory.end_coverage

          rescue Exception => e
            @logger.debug "Exception #{e.inspect} occured for #{census_employee.full_name}"
          end
        end

        expiring_plan_year.expire! if expiring_plan_year.may_expire?
      end
    end

    def create_active_benefit_group_assignments(benefit_groups)
      benefit_group_ids = benefit_groups.map(&:id)

      @employer_profile.census_employees.non_terminated.each do |census_employee|
        next if census_employee.active_benefit_group_assignment.present? && benefit_group_ids.include?(census_employee.active_benefit_group_assignment.benefit_group_id)
        if valid_bg_assignment = census_employee.benefit_group_assignments.renewing.detect{|bg_assignment| benefit_group_ids.include?(bg_assignment.benefit_group_id)}
          valid_bg_assignment.make_active
        end
      end
    end
  end   
end