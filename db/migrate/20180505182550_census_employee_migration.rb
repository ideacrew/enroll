class CensusEmployeeMigration < Mongoid::Migration

  def self.up

    # Census employee model is going to stay in main app. we currently don't need this migartion.

    # Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    #
    # file_name = "#{Rails.root}/hbx_report/census_employee_status#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    # field_names = %w( census_employee_id  status)
    #
    # logger = Logger.new("#{Rails.root}/log/census_employee_migration.log")
    # logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    #
    # CSV.open(file_name, 'w') do |csv|
    #   csv << field_names
    #   status = create_census_employee(csv, logger)
    #   if status
    #     puts "Check the report and logs for futher information"
    #   else
    #     puts "Data migration failed"
    #   end
    # end
  end

  def self.down

  end

  private

  def create_census_employee(csv, logger)
    say_with_time("Time taken to pull all old organizations with plan years") do

      begin
        CensusEmployee.unscoped.batch_size(2000).no_timeout.each do |old_census|
          census_employee = initialize_census_employee(sanitize_census_params(old_census))
          census_employee.census_dependents = initialize_census_dependent(old_census)
          census_employee.address = initialize_census_address(sanitize_address_params(old_census))
          census_employee.email = initialize_census_email(sanitize_email_params(old_census))
          census_employee.benefit_sponsorship = active_benefit_sponsorship(old_census)
          census_employee.save!
        end
      rescue Exception => e
        e.inspect unless Rails.env.test?
      end
    end
  end

  def initialize_census_employee(params)
    BenefitSponsors::CensusMembers::CensusEmployee.new(params)
  end

  def initialize_census_dependent(old_census)
    return [] unless old_census.census_dependents.present?
    [] << old_census.census_dependents.each do |dependent|
      BenefitSponsors::CensusMembers::CensusDependent.new(sanitize_dependent_params(dependent))
    end
  end

  def initialize_census_address(params)
    BenefitSponsors::Locations::Address.new(params)
  end

  def initialize_census_email(params)
    BenefitSponsors::Email.new(params)
  end

  def active_benefit_sponsorship(old_census)
    hbx_id = old_census.employer_profile.hbx_id
    BenefitSponsors::Organizations::Organization.where(hbx_id:hbx_id).first.active_benefit_sponsorship
  end

  def sanitize_census_params(old_census)
    json_data = old_census.to_json(:except => [:_id, :address, :emails, :census_dependents, :benefit_group_assignments, :workflow_state_transitions, :_type, :employer_profile_id])
    JSON.parse(json_data)
  end

  def sanitize_dependent_params(dependent)
    json_data = dependent.to_json(:except => [:_id, :_type])
    JSON.parse(json_data)
  end

  def sanitize_address_params(old_census)
    JSON.parse(old_census.address.to_json(:except => [:_id])) if old_emp.address.present?
  end

  def sanitize_email_params(old_census)
    JSON.parse(old_census.emails.to_json(:except => [:_id])) if old_emp.emails.present?
  end
end