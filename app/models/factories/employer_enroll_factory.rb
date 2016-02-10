module Factories
  class EmployerEnrollFactory

    attr_accessor :employer_profile, :date

    def begin
      current_plan_year = @employer_profile.plan_years.published_or_renewing_published.where(:"start_on" => @date || TimeKeeper.date_of_record).first

      census_employee_factory = Factories::CensusEmployeeFactory.new
      census_employee_factory.plan_year = current_plan_year

      @employer_profile.census_employees.non_terminated.each do |census_employee|
        begin
          census_employee_factory.census_employee = census_employee
          census_employee_factory.begin_coverage

        rescue Exception => e
          puts "Exception #{e.inspect} occured for #{census_employee.full_name}"
        end
      end

      current_plan_year.advance_date! if current_plan_year.may_advance_date?
      @employer_profile.advance_date! if @employer_profile.may_advance_date?

      create_active_benefit_group_assignments(current_plan_year.benefit_groups)
    end

    def end
      expiring_plan_year = @employer_profile.plan_years.published_or_renewing_published.where(:"end_on" => ((@date || TimeKeeper.date_of_record) - 1.day)).first

      census_employee_factory = Factories::CensusEmployeeFactory.new
      census_employee_factory.plan_year = expiring_plan_year

      @employer_profile.census_employees.non_terminated.each do |census_employee|
        begin
          census_employee_factory.census_employee = census_employee
          census_employee_factory.end_coverage

        rescue Exception => e
          puts "Exception #{e.inspect} occured for #{census_employee.full_name}"
        end
      end

      expiring_plan_year.advance_date! if expiring_plan_year.may_advance_date?
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