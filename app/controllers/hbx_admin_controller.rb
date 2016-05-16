class HbxAdminController < ApplicationController

  def edit_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?
    @months_array = Date::ABBR_MONTHNAMES.compact
    @current_year = TimeKeeper.date_of_record.year
    @person = Person.find(params[:person_id])
    @family = Family.find(params[:family_id])
    #@hbx = HbxEnrollment.find(params[:hbx_enrollment_id]) if params[:hbx_enrollment_id].present? This will be needed when we need to firure out which hbx we are editing when doing calculate available.
    @hbxs = @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)
    @household_info = HbxAdmin.build_household_level_aptc_csr_data(@family, @hbx)
    @slcsp_value = HbxAdmin.calculate_slcsp_value(@family)
    @household_members = HbxAdmin.build_household_members(@family)
    @enrollments_info = HbxAdmin.build_enrollments_data(@family, @hbxs)
    @no_enrollment = @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year).blank?
    @current_aptc_applied_hash =  HbxAdmin.build_current_aptc_applied_hash(@hbxs)
    @aptc_applied_for_all_hbxs = @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year).map{|h| h.applied_aptc_amount.to_f}.sum || 0
    @plan_premium_for_enrollments = HbxAdmin.build_plan_premium_hash_for_enrollments(@hbxs)
    @max_aptc = @family.active_household.latest_active_tax_household.latest_eligibility_determination.max_aptc

    @csr_percent_as_integer = @family.active_household.latest_active_tax_household.latest_eligibility_determination.csr_percent_as_integer

    respond_to do |format|
      format.js { render (@no_enrollment ? "edit_aptc_csr_no_enrollment" : "edit_aptc_csr_active_enrollment")}
      #format.js { render "edit_aptc_csr", person: @person, person_has_active_enrollment: @person_has_active_enrollment}
    end
  end

  def calculate_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?
    @months_array = Date::ABBR_MONTHNAMES.compact
    @current_year = TimeKeeper.date_of_record.year
    @person = Person.find(params[:person_id])
    @family = Family.find(params[:family_id])
    @hbx = HbxEnrollment.find(params[:hbx_enrollment_id]) if params[:hbx_enrollment_id].present?
    @hbxs = @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)
    @grid_vals = HbxAdmin.build_grid_values_for_aptc_csr(@family, @hbx, params[:max_aptc].to_f, params[:aptc_applied].to_f, params[:csr_percentage].to_i, params[:member_ids])
    @no_enrollment = @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year).blank?
    #@aptc_applied = params[:aptc_applied] || @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year).try(:first).try(:applied_aptc_amount) || 0
    @aptc_applied = params[:aptc_applied] || @hbx.applied_aptc_amount || 0 
    @max_aptc = params[:max_aptc] || @family.active_household.latest_active_tax_household.latest_eligibility_determination.max_aptc
    @csr_percent_as_integer = params[:csr_percentage] || @family.active_household.latest_active_tax_household.latest_eligibility_determination.csr_percent_as_integer

    respond_to do |format|
      format.js { render "edit_aptc_csr", person: @person, person_has_active_enrollment: @person_has_active_enrollment}
    end
  end

  def update_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?
    @person = Person.find(params[:person][:person_id]) if params[:person].present? && params[:person][:person_id].present?
    @family = Family.find(params[:person][:family_id]) if params[:person].present? && params[:person][:family_id].present?
    hbx    = HbxEnrollment.find(params[:person][:hbx_enrollment_id]) if params[:person].present? && params[:person][:hbx_enrollment_id].present?

    if @family.present?
      # Update Max APTC and CSR Percentage
      max_aptc = @family.active_household.latest_active_tax_household.latest_eligibility_determination.max_aptc
      csr_percent_as_integer = @family.active_household.latest_active_tax_household.latest_eligibility_determination.csr_percent_as_integer
      
      existing_latest_eligibility_determination = @family.active_household.latest_active_tax_household.latest_eligibility_determination
      latest_active_tax_household = @family.active_household.latest_active_tax_household

      if (params[:max_aptc].to_f == max_aptc) && (params[:csr_percentage].to_i == csr_percent_as_integer)
        # Dont Update.
      else
        # If max_aptc / csr percent is updated, create a new eligibility_determination with a new "determined_on" timestamp and the corresponsing csr/aptc update.
        latest_active_tax_household.eligibility_determinations.build({"determined_at"                 => TimeKeeper.datetime_of_record, 
                                                                      "determined_on"                 => TimeKeeper.datetime_of_record, 
                                                                      "csr_eligibility_kind"          => existing_latest_eligibility_determination.csr_eligibility_kind, 
                                                                      "premium_credit_strategy_kind"  => existing_latest_eligibility_determination.premium_credit_strategy_kind, 
                                                                      "csr_percent_as_integer"        => params[:csr_percentage].to_i, 
                                                                      "max_aptc"                      => params[:max_aptc].to_f, 
                                                                      "benchmark_plan_id"             => existing_latest_eligibility_determination.benchmark_plan_id,
                                                                      "e_pdc_id"                      => existing_latest_eligibility_determination.e_pdc_id  
                                                                      }).save!
      end
      
      # Update APTC Applied if there is an existing hbx_enrollment
      if params[:aptc_applied].present? && hbx.present?
        hbx.applied_aptc_amount = Money.new(params[:aptc_applied].to_f*100, "USD")
        hbx.save
      end



      # hbx_enrollment = @family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year).first
      # if params[:aptc_applied].present? && hbx_enrollment.present?
      #   hbx_enrollment.applied_aptc_amount = Money.new(params[:aptc_applied].to_f*100, "USD")
      #   hbx_enrollment.save
      # end
      
      # Update  Individuals Coverage Eligibility
      # We are not updating eligibility on an individual level - at least not until now. Eligibility resides on the tax_household level. 
      # Hence commenting the code below for now.

      # tax_household_members = @family.active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year).try(:tax_household_members)
      # tax_household_members.each do |member|
      #   if params.has_key?(member.person.id.to_s) || (params[:person][:person_id] == member.person.id.to_s) # The second condition is to include the primary applicant who is always eligible.
      #     member.is_ia_eligible = true
      #   else
      #     member.is_ia_eligible = false
      #   end
      #   member.save! 
      # end


    end

    respond_to do |format|
      format.js { render "update_aptc_csr", person: @person}
    end
  end

end
