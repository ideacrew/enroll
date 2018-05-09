class GroupSelectionPrevaricationAdapter
	attr_accessor :person
	attr_accessor :family
	attr_accessor :coverage_household
	attr_accessor :previous_hbx_enrollment
	attr_accessor :change_plan
	attr_accessor :coverage_kind
	attr_accessor :enrollment_kind
	attr_accessor :shop_for_plans
	attr_accessor :optional_effective_on

	include ActiveModel::Model

	def self.initialize_for_common_vars(params)
		person_id = params.require(:person_id)
		person = Person.find(person_id)
		family = person.primary_family
		coverage_household = family.active_household.immediate_family_coverage_household
		change_plan = params[:change_plan].present? ? params[:change_plan] : ''
		coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
		enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
		shop_for_plans = params[:shop_for_plans].present? ? params{:shop_for_plans} : ''
		optional_effective_on = params[:effective_on_option_selected].present? ? Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y') : nil
		record = self.new(
			person: person,
			family: family,
			coverage_household: coverage_household,
			change_plan: change_plan,
			coverage_kind: coverage_kind,
			enrollment_kind: enrollment_kind,
			shop_for_plans: shop_for_plans,
			optional_effective_on: optional_effective_on
		)
		if params[:hbx_enrollment_id].present?
			record.previous_hbx_enrollment = HbxEnrollment.find(params[:hbx_enrollment_id])
		end
		record.check_shopping_roles(params)
		record
	end

	def check_shopping_roles(params)
		if params[:employee_role_id].present?
			emp_role_id = params.require(:employee_role_id)
			@employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
		elsif params[:resident_role_id].present?
			@resident_role = @person.resident_role
		end
	end

	def can_ivl_shop?(params)
		(select_market(params) == 'individual') || (@person.try(:has_active_employee_role?) && @person.try(:has_active_consumer_role?)) || @person.resident_role?
	end

	def possible_resident_person
		@person.resident_role? ? @person : nil
	end

	def if_changing_ivl?(params)
		params[:hbx_enrollment_id].present?
	end

	def possible_employee_role
		if @employee_role.nil? && @person.has_active_employee_role?
			@person.active_employee_roles.first
		else
			@employee_role
		end
	end

	def if_employee_role
		return nil unless @employee_role.present?
		yield @employee_role
	end

	def if_resident_role
		return nil unless @resident_role.present?
		yield @resident_role
	end

	def if_consumer_role
		return nil if @employee_role.present? || @resident_role.present?
		yield person.consumer_role
	end

	def set_mc_variables
		if @previous_hbx_enrollment.present? && @change_plan == "change_plan"
			m_kind = @previous_hbx_enrollment.kind == "employer_sponsored" ? "shop" : "individual"
			yield m_kind, @previous_hbx_enrollment.coverage_kind
		end
	end

	def disable_market_kinds(params)
		if (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep')
			d_market_kind = (select_market(params) == "shop") ? "individual" : "shop"
			yield d_market_kind
		end
	end

  def ivl_benefit
    correct_effective_on = calculate_ivl_effective_on
    HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select{|bcp| bcp.contains?(correct_effective_on)}.first.benefit_packages.select{|bp|  bp[:title] == "individual_health_benefits_#{correct_effective_on.year}"}.first
  end

	def calculate_ivl_effective_on
		calculate_effective_on(market_kind: 'individual', employee_role: nil, benefit_group: nil)
	end

  def calculate_new_effective_on(params)
    benefit_group = select_benefit_group(params)
    calculate_effective_on(market_kind: select_market(params), employee_role: possible_employee_role, benefit_group: benefit_group)
  end

	def calculate_effective_on(market_kind:, employee_role:, benefit_group:)
		HbxEnrollment.calculate_effective_on_from(
			market_kind: market_kind,
			qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
			family: @family,
			employee_role: employee_role,
			benefit_group: benefit_group,
			benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship))
	end

  def if_qle_with_date_option_selected(params)
    if params[:effective_on_option_selected].present?
      yield Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y')
    end
  end

  def generate_coverage_family_members_for_cobra(params)
    if (select_market(params) == 'shop') && !(@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && possible_employee_role.present? && possible_employee_role.is_cobra_status?
      hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
      if hbx_enrollment.present?
        yield(hbx_enrollment.hbx_enrollment_members.map(&:family_member))
      end
    end
  end

	def ensure_previous_shop_sep_enrollment_if_not_provided(params)
		if (select_market(params) == 'shop') && (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && @previous_hbx_enrollment.blank?
			@previous_hbx_enrollment = selected_enrollment(@family, possible_employee_role)
      @can_waive = @previous_hbx_enrollment.can_complete_shopping?
		end
	end

  def is_qle?
    (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep')
  end

  def can_waive?(params)
    @can_waive
  end

	def select_benefit_group(params)
		if (select_market(params) == "shop") && @employee_role.present?
			@employee_role.benefit_group(qle: is_qle?)
		else
			nil
		end
	end

	def selected_enrollment(family, employee_role)
		employer_profile = employee_role.employer_profile
		py = employer_profile.plan_years.detect { |py| is_covered_plan_year?(py, family.current_sep.effective_on)} || employer_profile.published_plan_year
		enrollments = family.active_household.hbx_enrollments
		if py.present? && py.is_renewing?
			renewal_enrollment(enrollments, employee_role)
		else
			active_enrollment(enrollments, employee_role)
		end
	end

	def renewal_enrollment(enrollments, employee_role)
		enrollments.where({
			:"benefit_group_id" => employee_role.census_employee.renewal_published_benefit_group.try(:id),
			:"aasm_state".in => HbxEnrollment::RENEWAL_STATUSES
		}).first
	end

	def active_enrollment(enrollments, employee_role)
		enrollments.where({
			:"benefit_group_id" => employee_role.census_employee.active_benefit_group.try(:id),
			:"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES
		}).first
	end

	def select_market(params)
		return params[:market_kind] if params[:market_kind].present?
		if params[:qle_id].present? && (!person.has_active_resident_role?)
			qle = QualifyingLifeEventKind.find(params[:qle_id])
			return qle.market_kind
		end
		if person.has_active_employee_role?
			'shop'
		elsif person.has_active_consumer_role? && !person.has_active_resident_role?
			'individual'
		elsif person.has_active_resident_role?
			'coverall'
		else
			nil
		end
	end
end
