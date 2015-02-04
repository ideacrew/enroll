require "irs_groups/irs_group_builder"

class FamilyBuilder

  attr_reader :family

  attr_reader :save_list

  def initialize(param, person_mapper)
    @save_list = [] # it is observed that some embedded objects are not saved. We add all embedded/associated objects to this list and save them explicitly
    @is_update = true # true = we update an existing application group, false = we create a new application group
    @applicants_params = param[:family_members]
    @params = param
    filtered_param = param.slice(:e_case_id, :submitted_at, :e_status_code, :application_type)
    @person_mapper = person_mapper
    @family = Family.where(e_case_id: filtered_param[:e_case_id]).first
    @new_applicants = [] #this will include all the new applicants objects we create. In case of update application_group will have old applicants
    if @family.nil?
      @family = Family.new(filtered_param) #we create a new application group from the xml
      @is_update = false # means this is a create
    end

    @family.submitted_at = filtered_param[:submitted_at]
    @family.updated_by = "curam_system_service"

    get_household
  end

  def build
    add_tax_households(@params.to_hash[:tax_households])
    add_financial_statements(@params[:family_members])
    add_hbx_enrollment
    add_coverage_household
    return_obj = save
    add_irsgroups
    return_obj
  end

  def add_family_member(family_member_params)

    if @family.family_members.map(&:person_id).include? family_member_params[:person].id
       #puts "Added already existing applicant"
      applicant = @family.family_members.where(person_id: family_member_params[:person].id).first
    else
       #puts "Added a new applicant"
      if family_member_params[:is_primary_applicant] == "true"
        reset_exisiting_primary_applicant
      end

      applicant = @family.family_members.build(filter_applicant_params(family_member_params))

      @new_applicants << applicant

      member = applicant.person.members.select do |m|
        m.authority?
      end.first
      set_person_demographics(member, family_member_params[:person_demographics])
      set_alias_ids(member, family_member_params[:alias_ids])
      @save_list << member
      @save_list << applicant
      # puts "family_member_params[:is_primary_applicant] #{family_member_params[:is_primary_applicant]} @application_group.family_members #{applicant.inspect}"
    end

    applicant
  end

  def set_alias_ids(member, alias_ids_params)
    alias_ids_params.each do |alias_id_params|
      if alias_id_params.include? "aceds"
          member.aceds_id = alias_id_params.split('#').last
      elsif alias_id_params.include? "concern_role"
          member.e_concern_role_id = alias_id_params.split('#').last
      elsif alias_id_params.include? "person"
          member.e_person_id = alias_id_params.split('#').last
      end
    end
  end

  def reset_exisiting_primary_applicant
    @family.family_members.each do |applicant|
      applicant.is_primary_applicant = false
    end
  end

  def set_person_demographics(member, person_demographics_params)
    member.dob = person_demographics_params["dob"] if person_demographics_params["dob"]
    member.death_date = person_demographics_params["death_date"] if person_demographics_params["death_date"]
    member.ssn = person_demographics_params["ssn"] if person_demographics_params["ssn"]
    member.gender = person_demographics_params["gender"] if person_demographics_params["gender"]
    member.ethnicity = person_demographics_params["ethnicity"] if person_demographics_params["ethnicity"]
    member.race = person_demographics_params["race"] if person_demographics_params["race"]
    member.marital_status = person_demographics_params["marital_status"] if person_demographics_params["marital_status"]
  end

  def filter_applicant_params(applicant_params)
    applicant_params = applicant_params.slice(
        :is_primary_applicant,
        :is_coverage_applicant,
        :person)

    applicant_params.delete_if do |k, v|
      v.nil?
    end

    applicant_params
  end

  def get_household

    return @household if @household
    if !@is_update
      # puts "New Application Group Case"
      @household = self.family.households.build #if new application group then create new household
      @save_list << @household
    elsif have_applicants_changed?
      # puts "Update Application Group Case - Applicants have changed. Creating new household"
      @household = self.family.households.build #if applicants have changed then create new household
      @save_list << @household
    else
      @household = self.family.active_household #if update and applicants haven't changed then use the active household
    end

    return @household

  end

  def have_applicants_changed?

    current_list = @family.family_members.map do |applicant|
      applicant.person_id
    end.sort

    new_list = @applicants_params.map do |applicants_param|
      applicants_param[:person].id
    end.sort

    if current_list == new_list
      return false
    else
      return true
    end
  end

  def add_coverage_household

    return if @new_applicants.length == 0

    #TODO decide where to get submitted_at from
    coverage_household = @household.coverage_households.build({submitted_at: Time.now})

    @new_applicants.each do |applicant|
      if applicant.is_coverage_applicant
        coverage_household_member = coverage_household.coverage_household_members.build
        coverage_household_member.applicant_id = applicant.id
      end
    end

  end

  def add_hbx_enrollment

    # puts @application_group.primary_applicant

    @family.primary_applicant.person.policies.each do |policy|

      hbx_enrollement = @household.hbx_enrollments.build
      hbx_enrollement.policy = policy
      @family.primary_applicant.broker_id = Broker.find(policy.broker_id) unless policy.broker_id.blank?
      #hbx_enrollement.employer = Employer.find(policy.employer_id) unless policy.employer_id.blank?
      #hbx_enrollement.broker   = Broker.find(policy.broker_id) unless policy.broker_id.blank?
      #hbx_enrollement.primary_applicant = alpha_person
      #hbx_enrollement.allocated_aptc_in_dollars = policy.allocated_aptc
      hbx_enrollement.enrollment_group_id = policy.eg_id
      hbx_enrollement.elected_aptc_in_dollars = policy.elected_aptc
      hbx_enrollement.applied_aptc_in_dollars = policy.applied_aptc
      hbx_enrollement.submitted_at = Time.now

      hbx_enrollement.kind = "employer_sponsored" unless policy.employer_id.blank?
      hbx_enrollement.kind = "unassisted_qhp" if (hbx_enrollement.applied_aptc_in_cents == 0 && policy.employer.blank?)
      hbx_enrollement.kind = "insurance_assisted_qhp" if (hbx_enrollement.applied_aptc_in_cents > 0 && policy.employer.blank?)

      policy.enrollees.each do |enrollee|
        begin
          person = Person.find_for_member_id(enrollee.m_id)

          @family.family_members << FamilyMember.new(person: person) unless @family.person_is_family_member?(person)
          applicant = @family.find_family_member_by_person(person)

          hbx_enrollement_member = hbx_enrollement.hbx_enrollment_members.build({family_member: applicant,
                                                                                 premium_amount_in_cents: enrollee.pre_amt})
          hbx_enrollement_member.is_subscriber = true if (enrollee.rel_code == "self")

        rescue FloatDomainError
          # puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
          next
        end
      end

    end

  end

  #TODO currently only handling case we create new application case, where 1 irs group is built with 1 coverage household.
  def add_irsgroups
    if @is_update
      irs_group_builder = IrsGroupBuilder.new(self.family.id)
      irs_group_builder.update
    else
      irs_group_builder = IrsGroupBuilder.new(self.family.id)
      irs_group_builder.build
      irs_group_builder.save
    end
  end

  def add_tax_households(tax_households_params)

    tax_households_params.map do |tax_household_params|

      tax_household = @household.tax_households.build(filter_tax_household_params(tax_household_params))

      eligibility_determinations_params = tax_household_params[:eligibility_determinations]

      eligibility_determinations_params.each do |eligibility_determination_params|
        tax_household.eligibility_determinations.build(eligibility_determination_params)
      end

      tax_household_params[:tax_household_members].map do |tax_household_member_params|
        tax_household_member = tax_household.tax_household_members.build(filter_tax_household_member_params(tax_household_member_params))
        person_uri = @person_mapper.alias_map[tax_household_member_params[:person_id]]
        person_obj = @person_mapper.people_map[person_uri].first
        new_applicant = get_applicant(person_obj)
        new_applicant = verify_person_id(new_applicant)
        tax_household_member.applicant_id = new_applicant.id
        tax_household_member.family_member = new_applicant
      end
    end
  end

  def verify_person_id(applicant)
    if applicant.id.to_s.include? "concern_role"

    end
    applicant
  end

  def filter_tax_household_member_params(tax_household_member_params)
    tax_household_member_params_clone = tax_household_member_params.clone

    tax_household_member_params_clone = tax_household_member_params_clone.slice(:is_ia_eligible, :is_medicaid_chip_eligible, :is_subscriber)
    tax_household_member_params_clone.delete_if do |k, v|
      v.nil?
    end
    tax_household_member_params_clone
  end

  def filter_tax_household_params(tax_household_params)
    tax_household_params = tax_household_params.slice(:id)
    tax_household_params.delete_if do |k, v|
      v.nil?
    end
  end

  ## Fetches the applicant object either from application_group or person_mapper
  def get_applicant(person_obj)
    new_applicant = self.family.family_members.find do |applicant|
      applicant.id == @person_mapper.applicant_map[person_obj.id].id
    end
    new_applicant = @person_mapper.applicant_map[person_obj.id] unless new_applicant
  end

  def add_financial_statements(applicants_params)
    applicants_params.map do |applicant_params|
      applicant_params[:financial_statements].each do |financial_statement_params|
        tax_household_member = find_tax_household_member(@person_mapper.applicant_map[applicant_params[:person].id])
        financial_statement = tax_household_member.financial_statements.build(filter_financial_statement_params(financial_statement_params))
        financial_statement_params[:incomes].each do |income_params|
          financial_statement.incomes.build(income_params)
        end
        financial_statement_params[:deductions].each do |deduction_params|
          financial_statement.deductions.build(deduction_params)
        end
        financial_statement_params[:alternative_benefits].each do |alternative_benefit_params|
          financial_statement.alternate_benefits.build(alternative_benefit_params)
        end
      end
    end
  end

=begin
  def add_financial_statements(applicants_params)
    applicants_params.map do |family_member_params|
      family_member_params[:financial_statements].each do |financial_statement_params|
        tax_household_member = find_tax_household_member(@person_mapper.applicant_map[family_member_params[:person].id])
        financial_statement = tax_household_member.financial_statements.build(filter_financial_statement_params(financial_statement_params))
        financial_statement_params[:incomes].each do |income_params|
          financial_statement.incomes.build(income_params)
        end
        financial_statement_params[:deductions].each do |deduction_params|
          financial_statement.deductions.build(deduction_params)
        end
        financial_statement_params[:alternative_benefits].each do |alternative_benefit_params|
          financial_statement.alternate_benefits.build(alternative_benefit_params)
        end
      end
    end
  end
=end

  def filter_financial_statement_params(financial_statement_params)

    financial_statement_params = financial_statement_params.slice(:type, :is_tax_filing_together, :tax_filing_status)

    financial_statement_params.delete_if do |k, v|
      v.nil?
    end
  end

  def find_tax_household_member(applicant)
    tax_household_members = self.family.households.flat_map(&:tax_households).flat_map(&:tax_household_members)

    tax_household_member = tax_household_members.find do |tax_household_member|
      tax_household_member.applicant_id == applicant.id
    end

    tax_household_member
  end

  def save
    id = @family.save!
    save_save_list
    @family #return the saved family
  end

  #save objects in save list
  def save_save_list
    save_list.each do |obj|
      obj.save!
    end
  end
end
