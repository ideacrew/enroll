require "tasks/hbx_import/employer_monkeypatch"

module HbxImport
  class EmployerImport
    attr_reader :employer_file_name, :ignore_file_name
    attr_accessor :employers, :user_blacklist, :employer_organizations

    def initialize(employer_file_name, ignore_file_name)
      @employer_file_name = employer_file_name
      @ignore_file_name   = ignore_file_name
      @employers = []
      @user_blacklist = []
      @employer_organizations = []
    end

    def run
      load_csv_data
      puts "Found #{employers.size} employers with #{employers.flat_map(&:locations).size} locations."
      puts "Found #{user_blacklist.size} usernames to ignore."

      remove_blacklisted_employers
      puts "Left with #{employers.size} employers with #{employers.flat_map(&:locations).size} locations."

      create_employer_organizations
      puts "Found #{found_employer_organization_count} organizations."
      puts "Created #{new_employer_organizations_count} new organizations."

      saved_employer_organization_count = save_employer_organizations
      puts "Successfully saved #{saved_employer_organization_count} new organizations."
    end

    def load_csv_data
      # load_plan_lookups
      load_employers
      load_user_blacklist
    end

    def load_plan_lookups
      CSV.foreach(plan_lookup_file_name, headers: true) do |row|
        PlanLookup.add_from_row(row)
      end
    end

    def load_employers
      CSV.foreach(employer_file_name, headers: true) do |row|
        employers << Employer.from_row(row)
      end
      sort_employers
    end

    def sort_employers
      employers.sort_by! do |employer|
        [employer.fein, employer.user_name, employer.company_external_id, employer.complete_date]
      end
      # TODO: remove this, it is temporary to ensure the latest org instance is first
      employers.reverse!
    end

    def load_user_blacklist
      CSV.foreach(ignore_file_name, headers: false) do | row |
        user_blacklist << row[0] if row[0].present?
      end
      user_blacklist.uniq!
    end

    def remove_blacklisted_employers
      user_blacklist.each do |user|
        employers.delete_if {|employer| employer.user_name == user}
      end
    end

    def create_employer_organizations
      self.employer_organizations = employers.collect(&:create_or_update_employer_organization)
    end

    def found_employer_organization_count
      employers.reduce(0) do |count, employer|
        if Organization.where("fein" => employer.fein).any?
          count + 1
        else
          count
        end
      end
    end

    def new_employer_organizations_count
      employer_organizations.reject(&:persisted?).count
    end

    def save_employer_organizations
      employer_organizations.reduce(0) do |count, organization|
        if organization.valid? && !organization.persisted?
          organization.save
          if organization.persisted?
            count + 1
          else
            # TODO: error saving
            puts organization.inspect
            puts organization.errors.full_messages.inspect
            unless organization.employer_profile.valid?
              puts organization.employer_profile.errors.full_messages.inspect
            end
            count
          end
        else
          if organization.valid?
            count
          else
            #TODO: print errors?
            # puts "Error validating new organization:"
            # puts [o, o.office_locations, o.employer_profile, o.errors].collect(&:inspect)
            puts organization.inspect
            puts organization.errors.full_messages.inspect
            unless organization.employer_profile.valid?
              puts organization.employer_profile.errors.full_messages.inspect
            end
            count
          end
        end
      end
    end
  end

  Employer = Struct.new(
      :app_response_code, :enroll_type, :complete_date, :user_name,
      :company_external_id, :fein, :dba, :legal_name,
      :previous_effective_date, :effective_date, :open_enrollment_start,
      :open_enrollment_end, :poc_first_name, :poc_last_name, :poc_email,
      :poc_phone, :census_count, :new_hire_wait_index,
      :new_hire_wait_description, :address_1,
      :address_2, :city, :state, :zip, :carrier_name, :locations,
      :broker_agency_id, :broker_first_name, :broker_last_name, :broker_email,
      :broker_external_id, :broker_npn, :assign_enter_date, :assign_end_date
  ) do
    def self.from_row(row)
      employer = Employer.new()
      employer.app_response_code           = row[0].to_i
      employer.enroll_type                 = row[1]
        # initial or renewal

      employer.complete_date               = row[2].to_date_safe
      employer.user_name                   = row[3]
      employer.company_external_id         = row[4].to_digits
      employer.fein                        = row[5].to_digits
      employer.dba                         = row[6]
      employer.legal_name                  = row[7]

      employer.previous_effective_date     = row[8]
      employer.effective_date              = row[9].to_date_safe
      employer.open_enrollment_start       = row[10].to_date_safe
      employer.open_enrollment_end         = row[11].to_date_safe

      employer.poc_first_name              = row[12]
      employer.poc_last_name               = row[13]
      employer.poc_email                   = row[14]
      employer.poc_phone                   = row[15].to_digits

      employer.census_count                = row[16].to_i
      employer.new_hire_wait_index         = row[17].to_i
      employer.new_hire_wait_description   = row[18]
        # "Date of Hire equal to Effective Date"
        # "First of the month following date of hire"
        # "First of the month following 30 days"
        # "First of the month following 60 days"

      employer.address_1                   = row[19]
      employer.address_2                   = row[20]
      employer.city                        = row[21]
      employer.state                       = row[22]
      employer.zip                         = row[23]
      employer.carrier_name                = row[24]

      # switched to column labels because row numbers changed
      # the rest should probably be switched to this
      # but it can wait
      employer.broker_agency_id            = row["BROKERCOMPANYID"].to_i
      employer.broker_first_name           = row["AGENT_FIRST_NAME"]
      employer.broker_last_name            = row["AGENT_LAST_NAME"]
      employer.broker_email                = row["AGENT_EMAIL"]
      employer.broker_external_id          = row["AGENT_EXTERNAL_ID"].to_i
      employer.broker_npn                  = row["AGENT_LICENSE_ID"]
      employer.assign_enter_date           = row["ASSIGN_ENTER_DATE"].to_date_safe
      employer.assign_end_date             = row["ASSIGN_END_DATE"].to_date_safe

      employer.locations = locations_from_row(row, employer)
      employer
    end

    def self.locations_from_row(row, employer)
      loc_index = 25
      loc_fields = Location.members.count - 1 # employer is artificially injected at the beginning
      n_locs = 10
      (loc_index...(loc_index + (loc_fields * n_locs))).step(loc_fields).flat_map do |base|
        location_fields = [employer] + row.fields(base...(base + loc_fields))
        location = Location.from_row(*location_fields)
        location.present? ? location : []
      end
    end

    attr_accessor :organization, :employer_profile, :plan_year

    def create_or_update_employer_organization
      # if organization exists compare with existing, and
      # update if this employer is the latest version
      self.organization = Organization.where("fein" => fein).first
      if organization.present?
        # TODO: for each updateable field, update if new
      else
        build_organization
        build_office_location
        build_employer_profile
        build_plan_year
        build_benefit_groups
        build_broker
      end
      organization
    end

    def build_organization
      self.organization = Organization.new
      organization.legal_name = legal_name
      organization.dba = dba
      organization.fein = fein
      organization.is_active = true
    end

    def build_office_location
      ol = OfficeLocation.new(organization: organization)

      ola = ol.build_address
      ola.kind = "work"
      ola.address_1 = address_1
      ola.address_2 = address_2
      ola.city = city
      ola.state = state
      ola.zip = zip

      olp = ol.build_phone
      olp.kind = "work"
      olp.full_phone_number = poc_phone
    end

    def build_employer_profile
      self.employer_profile = organization.build_employer_profile
      employer_profile.entity_kind = "c_corporation" # TODO: fix, this should probably come from the data
      # employer_profile.aasm_state = "binder_paid"
      if !broker_npn.blank?
        if broker_npn.to_s != "0"
          found_broker = BrokerRole.by_npn(broker_npn).first
          if found_broker.nil?
            puts "COULD NOT FIND BROKER FOR #{legal_name}, #{fein}, #{broker_npn}"
          else
            ba = employer_profile.broker_agency_accounts.build
            ba.writing_agent_id = found_broker.id
            ba.broker_agency_profile_id = found_broker.broker_agency_profile_id
            ba.start_on = open_enrollment_start
          end
        end
      end
    end

    def build_plan_year
      self.plan_year = employer_profile.plan_years.build
      plan_year.start_on = effective_date
      plan_year.end_on = ((effective_date + 1.year) - 1.day).to_date
      plan_year.open_enrollment_start_on = open_enrollment_start
      plan_year.open_enrollment_end_on = open_enrollment_end
      plan_year.fte_count = census_count
      # plan_year.aasm_state = "active"
      # plan_year.imported_plan_year = true
    end

    def build_benefit_groups
      p_location = locations.compact.first
      if p_location
        build_benefit_group(p_location, plan_year)
      end
    end

    def build_benefit_group(location, plan_year)
      benefit_group = location.create_or_update_benefit_group(self, plan_year)
    end

    def build_broker
      # oer.broker_agency_id = broker_agency_id # TODO: fix, this isn't really our broker_agency_id
      # oer.
    end
  end

  Location = Struct.new(
    :employer, :metal_selection, :plan_count, :reference_plan_name,
    :plan_display_name, :reference_plan_id, :hios_id, :employee_contribution,
    :dependent_contribution, :name
  ) do
    def self.from_row(*args)
      if args[3].present?
        args = args.dup
        int_indexes = [2,5,7,8]
        int_indexes.each {|i| args[i] = args[i].to_i}
        Location.new(*args)
      end
    end

    attr_accessor :benefit_group

    def create_or_update_benefit_group(employer, plan_year)
      build_benefit_group(employer, plan_year)
      build_benefit_group_plans(employer, plan_year)
      benefit_group.relationship_benefits =
        benefit_group.simple_benefit_list(employee_contribution, dependent_contribution, 0)
      benefit_group.relationship_benefits = benefit_group.simple_benefit_list(employee_contribution, dependent_contribution, 0)
      benefit_group
    end

    def build_benefit_group(employer, plan_year)
      self.benefit_group = plan_year.benefit_groups.build
      case employer.new_hire_wait_index
      when 1
        benefit_group.effective_on_kind = "date_of_hire"
        benefit_group.effective_on_offset = 0
      when 2
        benefit_group.effective_on_kind = "first_of_month"
        benefit_group.effective_on_offset = 0
      when 3
        benefit_group.effective_on_kind = "first_of_month"
        benefit_group.effective_on_offset = 30
      when 4
        benefit_group.effective_on_kind = "first_of_month"
        benefit_group.effective_on_offset = 60
      end
      benefit_group.employer_max_amt_in_cents = 0
      benefit_group.title = name
    end

    def build_benefit_group_plans(employer, plan_year)
      benefit_group.reference_plan = PlanLookup.find_reference_plan(hios_id, plan_year.start_on.year)
      build_benefit_group_elected_plan_ids(employer, plan_year)
    end

    def build_benefit_group_elected_plan_ids(employer, plan_year)
      reference_plan = benefit_group.reference_plan
      benefit_group.elected_plan_ids = case
      when plan_count == 1
        benefit_group.plan_option_kind = "single_plan"
        elected_plan_ids = [reference_plan._id]
      when metal_selection.present?
        benefit_group.plan_option_kind = "metal_level"
        elected_plan_ids = PlanLookup.find_plans_by_metal_level(metal_selection, reference_plan.active_year)
      when employer.carrier_name.present?
        benefit_group.plan_option_kind = "single_carrier"
        elected_plan_ids = PlanLookup.find_plans_by_carrier(reference_plan.carrier_profile, reference_plan.active_year)
      end
    end
  end

  PlanLookup = Struct.new(:carrier_name, :hios_id, :mapping_id, :display_name, :metal,
                          :cert_start_on, :cert_end_on, :activation_start_on,
                          :activation_end_on
  ) do

    def self.find_reference_plan(hios_id, year)
      key = "#{year} - #{hios_id}"
      @reference_plans = {} unless @reference_plans
      if @reference_plans.has_key?(key)
        @reference_plans[key]
      else
        @reference_plans[key] = Plan.shop_market.where(hios_id: hios_id).and(active_year: year).first
      end
    end

    def self.find_plans_by_carrier(carrier_profile, year)
      key = "#{year} - #{carrier_profile._id}"
      @carrier_plans = {} unless @carrier_plans
      if @carrier_plans.has_key?(key)
        @carrier_plans[key]
      else
        @carrier_plans[key] = carrier_profile.plans.where(active_year: year, market: "shop", coverage_kind: "health").collect(&:_id)
      end
    end

    def self.find_plans_by_metal_level(metal_level, year)
      key = "#{year} - #{metal_level}"
      @metal_plans = {} unless @metal_plans
      if @metal_plans.has_key?(key)
        @metal_plans[key]
      else
        @metal_plans[key] = Plan.shop_market.where(metal_level: metal_level).and(active_year: year, coverage_kind: "health").collect(&:_id)
      end
    end

    def self.add_from_row(row)
      lookup = PlanLookup.new
      lookup.carrier_name = row[1]
      lookup.hios_id = row[2]
      lookup.mapping_id = row[7]
      lookup.display_name = row[8]
      lookup.metal = row[11]
      lookup.cert_start_on = row[16].to_date_safe
      lookup.cert_end_on = row[17].to_date_safe
      lookup.activation_start_on = row[18].to_date_safe
      lookup.activation_end_on = row[19].to_date_safe
      lookups[[lookup.carrier_name, lookup.display_name]] = lookup
    end

    def self.lookup(carrier_name, plan_name)
      @lookups[[carrier_name, plan_name]]
    end

    private

    def self.lookups
      @lookups = {} if @lookups.nil?
      @lookups
    end
  end
end
