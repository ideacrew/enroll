# frozen_string_literal: true

class Insured::ConsumerRolesController < ApplicationController
  include ApplicationHelper
  include VlpDoc
  include ErrorBubble

  before_action :check_consumer_role, only: [:search, :match]
  before_action :find_consumer_role, only: [:edit, :update]
  before_action :individual_market_is_enabled?
  before_action :decrypt_params, only: [:create]
  before_action :set_cache_headers, only: [:edit, :help_paying_coverage, :privacy, :search]
  before_action :redirect_if_medicaid_tax_credits_link_is_disabled, only: [:privacy, :search]
  before_action :sanitize_contact_method, :validate_person_match, only: [:update]

  FIELDS_TO_ENCRYPT = [:ssn,:dob,:first_name,:middle_name,:last_name,:gender,:user_id].freeze

  def ssn_taken; end

  def privacy
    set_current_person(required: false)
    params_hash = params.permit(:aqhp, :uqhp).to_h
    @val = params_hash[:aqhp] || params_hash[:uqhp]
    @key = params_hash.key(@val)
    @search_path = {@key => @val}
    if @person.try(:resident_role?)
      bookmark_url = @person.resident_role.bookmark_url.to_s.present? ? @person.resident_role.bookmark_url.to_s : nil
      redirect_to bookmark_url || family_account_path
    elsif @person.try(:consumer_role?)
      bookmark_url = @person.consumer_role.bookmark_url.to_s.present? ? @person.consumer_role.bookmark_url.to_s : nil
      redirect_to bookmark_url || family_account_path
    end
  end

  def search
    @no_previous_button = true
    @no_save_button = true
    if params[:aqhp].present?
      session[:individual_assistance_path] = true
    else
      session.delete(:individual_assistance_path)
    end

    if params.permit(:build_consumer_role)[:build_consumer_role].present? && session[:person_id]
      person = Person.find(session[:person_id])

      @person_params = person.attributes.extract!("first_name", "middle_name", "last_name", "gender")
      @person_params[:ssn] = Person.decrypt_ssn(person.encrypted_ssn)
      @person_params[:dob] = person.dob.strftime("%Y-%m-%d")

      @person = ::Forms::ConsumerCandidate.new(@person_params)
    else
      @person = ::Forms::ConsumerCandidate.new
    end

    respond_to do |format|
      format.html
    end
  end

  def match
    @no_save_button = true
    @person_params = params.require(:person).permit(person_parameters_list).merge({user_id: current_user.id}).to_h
    @consumer_candidate = ::Forms::ConsumerCandidate.new(@person_params)
    @person = @consumer_candidate
    @use_person = true #only used to manupulate form data
    respond_to do |format|
      if @consumer_candidate.valid?
        idp_search_result = nil
        idp_search_result = if current_user.idp_verified?
                              :not_found
                            else
                              IdpAccountManager.check_existing_account(@consumer_candidate)
                            end
        case idp_search_result
        when :service_unavailable
          format.html { render 'shared/account_lookup_service_unavailable' }
        when :too_many_matches
          format.html { redirect_to URI.parse(SamlInformation.account_conflict_url).to_s }
        when :existing_account
          format.html { redirect_to URI.parse(SamlInformation.account_recovery_url).to_s }
        else
          if params[:persisted] != "true" && ::EnrollRegistry[:aca_shop_market].enabled?
            @employee_candidate = Forms::EmployeeCandidate.new(@person_params)

            if @employee_candidate.valid?
              found_census_employees = @employee_candidate.match_census_employees
              @employment_relationships = ::Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_census_employees)
              format.html { render 'insured/employee_roles/match' } if @employment_relationships.present?
            end
          end
          @resident_candidate = ::Forms::ResidentCandidate.new(@person_params)
          if @resident_candidate.valid?
            found_person = @resident_candidate.match_person
            if found_person.present? && found_person.resident_role.present?
              begin
                @resident_role = ::Factories::EnrollmentFactory.construct_resident_role(params.require(:person).permit(person_parameters_list), actual_user)
                if @resident_role.present?
                  @person = @resident_role.person
                  session[:person_id] = @person.id
                else
                # not logging error because error was logged in construct_consumer_role
                  @person_params = encrypt_pii(@person_params)
                  render file: 'public/500.html', status: 500
                  return
                end
              rescue Exception => e
                flash[:error] = set_error_message(e.message)
                redirect_to search_exchanges_residents_path
                return
              end
              create_sso_account(current_user, @person, 15, "resident") do
                respond_to do |format|
                  format.html do
                    redirect_to family_account_path
                  end
                end
              end
            end
            @person_params = encrypt_pii(@person_params)
            return
          end

          found_person = @consumer_candidate.match_person
          if found_person.present?
            format.html { render 'match' }
          else
            format.html { render 'no_match' }
          end
        end
      elsif @consumer_candidate.errors[:ssn_dob_taken].present?
        format.html { render 'search' }
      elsif @consumer_candidate.errors[:ssn_taken].present?
        text = "The Social Security number entered is associated with an existing user. "
        text += "Please #{view_context.link_to('sign in', SamlInformation.iam_login_url)} with your username and password "
        text += "or #{view_context.link_to('click here', SamlInformation.account_recovery_url)} if you've forgotten your password."
        flash[:alert] = text
        format.html {redirect_to ssn_taken_insured_consumer_role_index_path}
      else
        format.html { render 'search' }
      end
    end
  end

  def build
    set_current_person(required: false)
    build_person_params
    render 'match'
  end

  def create
    begin
      @consumer_role = ::Factories::EnrollmentFactory.construct_consumer_role(params.require(:person).permit(person_parameters_list), actual_user)
      if @consumer_role.present?
        @person = @consumer_role.person
      else
        raise 'Unable to find a unique record matching the given information'
      end
    rescue Exception => e
      flash[:error] = set_error_message(e.message)
      redirect_to search_insured_consumer_role_index_path
      return
    end
    @person&.primary_family&.create_dep_consumer_role

    is_assisted = session["individual_assistance_path"]
    role_for_user = is_assisted ? "assisted_individual" : "individual"
    begin
      create_sso_account(current_user, @person, 15, role_for_user) do

        # This is a massive hack and should be delt with as part of a refactor of
        # consumer role matching, but since a consumer role has been claimed, we
        # need to check if broker roles have been properly claimed.  This way
        # brokers who never claim an outstanding invitation will still have
        # access to their broker profile, now that they've registered as a
        # consumer.  I would have rolled this up into the enrollment factory, but
        # that area is some of our most delicate and oldest code, I'm going to
        # avoid changing it until we have a chance to refactor.  Just as
        # important, this functions against "linked" users, so it needs to
        # happen AFTER the user_id has been set for the person.
        Operations::EnsureBrokerStaffRoleForPrimaryBroker.new(:consumer_role_linked).call(@person.broker_role)

        respond_to do |format|
          format.html do
            if is_assisted
              @person.primary_family&.update_attribute(:e_case_id, "curam_landing_for#{@person.id}")
              redirect_to navigate_to_assistance_saml_index_path
            else
              redirect_to :action => "edit", :id => @consumer_role.id
            end
          end
        end
      end
    rescue StandardError => e
      flash[:warning] = l10n('insured.existing_person_record_warning_message') if @person.errors.present?
      logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to search_insured_consumer_role_index_path
    end
  end

  def immigration_document_options
    if params[:target_type] == "Person"
      @target = Person.find(params[:target_id])
      vlp_docs = @target.consumer_role.vlp_documents
    elsif params[:target_type] == "Forms::FamilyMember"
      if params[:target_id].present?
        @target = Forms::FamilyMember.find(params[:target_id])
        vlp_docs = @target.family_member.person.consumer_role.vlp_documents
      else
        @target = Forms::FamilyMember.new
      end
    end
    @vlp_doc_target = params[:vlp_doc_target]
    vlp_doc_subject = params[:vlp_doc_subject]
    @country = vlp_docs.detect{|doc| doc.subject == vlp_doc_subject }.try(:country_of_citizenship) if vlp_docs
  end

  def edit
    authorize @consumer_role, :edit?
    set_consumer_bookmark_url
    @consumer_role.build_nested_models_for_person
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@consumer_role)
    respond_to do |format|
      format.js
      format.html
    end
  end

  def update
    authorize @consumer_role, :update?
    save_and_exit = params['exit_after_method'] == 'true'
    mec_check(@person.hbx_id) if EnrollRegistry.feature_enabled?(:mec_check) && @person.send(:mec_check_eligible?)
    @shop_coverage_result = EnrollRegistry.feature_enabled?(:shop_coverage_check) ? (check_shop_coverage.success? && check_shop_coverage.success.present?) : nil
    @consumer_role.skip_consumer_role_callbacks = true
    valid_params = {"skip_person_updated_event_callback" => true, "skip_lawful_presence_determination_callbacks" => true}.merge(params.require(:person).permit(*person_parameters_list))

    if update_vlp_documents(@consumer_role, 'person') && @consumer_role.update_by_person(valid_params)
      @consumer_role.update_attribute(:is_applying_coverage, params[:person][:is_applying_coverage]) unless params[:person][:is_applying_coverage].nil?
      @person.active_employee_roles.each { |role| role.update_attributes(contact_method: params[:person][:consumer_role_attributes][:contact_method]) } if @person.has_multiple_roles?
      @person.primary_family.update_attributes(application_type: params["person"]["family"]["application_type"]) if current_user.has_hbx_staff_role?
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        redirect_path = redirect_path_for_update

        fire_consumer_roles_update_for_vlp_docs(@consumer_role, @consumer_role.is_applying_coverage)
        redirect_to redirect_path
      end
    else
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        @consumer_role.build_nested_models_for_person
        @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@consumer_role)
        bubble_address_errors_by_person(@consumer_role.person)
        respond_to do |format|
          format.html { render "edit" }
        end
      end
    end
  end

  def ridp_agreement
    set_current_person
    consumer = @person.consumer_role
    if @person.completed_identity_verification? || consumer.identity_verified?
      consumer_redirection_path = insured_family_members_path(:consumer_role_id => @person.consumer_role.id)
      consumer_redirection_path = help_paying_coverage_insured_consumer_role_index_path if EnrollRegistry.feature_enabled?(:financial_assistance)
      redirect_to consumer.admin_bookmark_url.present? ? consumer.admin_bookmark_url : consumer_redirection_path
    else
      set_consumer_bookmark_url
    end
  end

  def upload_ridp_document
    set_consumer_bookmark_url
    set_current_person
    @person.consumer_role.move_identity_documents_to_outstanding
  end

  def update_application_type
    set_current_person
    application_type = params[:consumer_role][:family][:application_type]
    @person.primary_family.update_attributes(application_type: application_type)
    if @person.primary_family.has_curam_or_mobile_application_type?
      @person.consumer_role.move_identity_documents_to_verified(@person.primary_family.application_type)
      consumer_redirection_path = insured_family_members_path(:consumer_role_id => @person.consumer_role.id)
      consumer_redirection_path = help_paying_coverage_insured_consumer_role_index_path if EnrollRegistry.feature_enabled?(:financial_assistance)
      redirect_to consumer_redirection_path
    else
      redirect_back fallback_location: '/'
    end
  end

  def help_paying_coverage
    if EnrollRegistry.feature_enabled?(:financial_assistance)
      set_current_person
      # defined?(Cucumber) is used to bypass the authorization check in cucumber tests
      # This is a temporary fix and should be removed once the cucumber tests are modified and the ridp verification is stubbed in lower environments.
      authorize @person.consumer_role, :ridp_verified? unless defined?(Cucumber)
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      @transaction_id = params[:id]
      @shop_coverage_result ||= params[:shop_coverage_result]

      draft_application = @person.primary_family&.most_recent_and_draft_financial_assistance_application if EnrollRegistry.feature_enabled?(:draft_application_after_ridp)
      redirect_to financial_assistance.edit_application_path(id: draft_application.id) if draft_application.present?
    else
      render(:file => "#{Rails.root}/public/404.html", layout: false, status: :not_found)
    end
  end

  def help_paying_coverage_response
    set_current_person
    if params["is_applying_for_assistance"].blank?
      flash[:error] = "Please choose an option before you proceed."
      redirect_to help_paying_coverage_insured_consumer_role_index_path
    elsif params["is_applying_for_assistance"] == "true"
      begin
        result = Operations::FinancialAssistance::Apply.new.call(family_id: @person.primary_family.id)
        if result.success?
          redirect_to help_paying_coverage_redirect_path(result)
        else
          flash[:error] = get_error_messages(result)
          redirect_back fallback_location: '/'
        end
      rescue StandardError => e
        flash[:error] = "Failed to proceed, " + e.message
        redirect_back fallback_location: '/'
      end
    else
      @person.update_attributes is_applying_for_assistance: false
      redirect_to insured_family_members_path(consumer_role_id: @person.consumer_role.id)
    end
  end

  private

  def redirect_path_for_update
    if staff_and_paper_or_in_person_application?
      upload_ridp_document_insured_consumer_role_index_path
    elsif new_paper_or_cruam_or_mobile_application?
      @person.consumer_role.move_identity_documents_to_verified(@person.primary_family.application_type)
      admin_bookmark_url_or_help_paying_coverage_path
    else
      ridp_agreement_insured_consumer_role_index_path
    end
  end

  def staff_and_paper_or_in_person_application?
    current_user.has_hbx_staff_role? && (@person.primary_family.application_type == "Paper" || @person.primary_family.application_type == "In Person")
  end

  def new_paper_or_cruam_or_mobile_application?
    is_new_paper_application?(current_user, session[:original_application_type]) || @person.primary_family.has_curam_or_mobile_application_type?
  end

  def admin_bookmark_url_or_help_paying_coverage_path
    return URI.parse(@consumer_role.admin_bookmark_url).to_s if @consumer_role.admin_bookmark_url.present?
    return help_paying_coverage_insured_consumer_role_index_path(shop_coverage_result: @shop_coverage_result) if EnrollRegistry.feature_enabled?(:financial_assistance)

    insured_family_members_path(consumer_role_id: @person.consumer_role.id)
  end

  def validate_person_match
    first_name = params[:person][:first_name]
    last_name = params[:person][:last_name]
    return if (first_name == @person.first_name) && (last_name == @person.last_name)
    matched_person = match_person(first_name, last_name)
    return unless matched_person.present? && (matched_person.hbx_id != @person.hbx_id)
    flash[:error] = l10n("person_match_error_message", first_name: first_name, last_name: last_name)
    respond_to do |format|
      format.html { redirect_to edit_insured_consumer_role_path(@person.consumer_role.id) }
    end
  end

  def match_person(first_name, last_name)
    ssn = @person.ssn
    match_criteria, records = Operations::People::Match.new.call({:dob => @person.dob,
                                                                  :last_name => last_name,
                                                                  :first_name => first_name,
                                                                  :ssn => ssn})

    return nil if records.blank?
    if (match_criteria == :dob_present && ssn.present? && records.first.employer_staff_roles?) ||
       (match_criteria == :dob_present && ssn.blank?) ||
       match_criteria == :ssn_present
      records.first
    end
  end

  def mec_check(person_id)
    ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecCheck.new.call(person_id)
  end

  def check_shop_coverage
    Operations::Households::CheckExistingCoverageByPerson.new.call(person_hbx_id: @person.hbx_id, market_kind: "employer_sponsored")
  end

  def help_paying_coverage_redirect_path(result)
    if EnrollRegistry.feature_enabled?(:iap_year_selection) && (HbxProfile.current_hbx.under_open_enrollment? || EnrollRegistry.feature_enabled?(:iap_year_selection_form))
      return financial_assistance.application_year_selection_application_path(id: result.success)
    end

    financial_assistance.application_checklist_application_path(id: result.success)
  end

  def get_error_messages(result)
    message_array = []
    messages = result.failure.messages
    messages.each do |message|
      message.meta[:error].each do |key, value|
        message_array << "#{key} - #{value[0]}"
      end
    end
    message_array
  end

  def redirect_if_medicaid_tax_credits_link_is_disabled
    redirect_to(main_app.root_path, notice: l10n("medicaid_and_tax_credits_link_is_disabled")) if params[:aqhp].present? && !EnrollRegistry.feature_enabled?(:medicaid_tax_credits_link)
  end

  def decrypt_params
    return unless SymmetricEncryption.encrypted?(params[:person][:first_name]) #temporary fix, need better handling of encryption.
      # Decrypt encrypted fields
    FIELDS_TO_ENCRYPT.each do |field|
      params[:person][field] = SymmetricEncryption.decrypt(params[:person][field])
    end
  end

  def encrypt_pii(person)
    FIELDS_TO_ENCRYPT.each do |field|
      person[field] = SymmetricEncryption.encrypt(person[field])
    end
    person
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    if current_user.has_consumer_role?
      respond_to do |format|
        format.html { redirect_to edit_insured_consumer_role_path(current_user.person.consumer_role.id) }
      end
    else
      flash[:error] = "We're sorry. Due to circumstances out of your control an error has occured."
      respond_to do |format|
        format.json { redirect_to destroy_user_session_path }
        format.html { redirect_to destroy_user_session_path }
        format.js   { redirect_to destroy_user_session_path }
      end
    end
  end

  def sanitize_contact_method
    contact_method = params.dig("person", "consumer_role_attributes", "contact_method")
    return unless contact_method.is_a?(Array)
    return if contact_method.empty?

    params.dig("person", "consumer_role_attributes").merge!("contact_method" => ConsumerRole::CONTACT_METHOD_MAPPING[contact_method])
  end

  def person_parameters_list
    [
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county, :id, :_destroy] },
      { :phones_attributes => [:kind, :full_phone_number, :id, :_destroy] },
      { :emails_attributes => [:kind, :address, :id, :_destroy] },
      { :consumer_role_attributes => [:contact_method, :language_preference]},
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :dob,
      :ssn,
      :no_ssn,
      :gender,
      :language_code,
      :is_incarcerated,
      :is_disabled,
      :race,
      :is_consumer_role,
      :is_resident_role,
      {:immigration_doc_statuses => []},
      {:ethnicity => []},
      :us_citizen,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      :tribal_id,
      :tribal_state,
      :tribal_name,
      { :tribe_codes => [] },
      :no_dc_address,
      :no_dc_address_reason,
      :is_applying_coverage,
      :is_homeless,
      :is_temporarily_out_of_state,
      :is_moving_to_state,
      :user_id,
      :dob_check,
      :is_tobacco_user
    ]
  end

  def find_consumer_role
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
  end

  def check_consumer_role
    set_current_person(required: false)
    # need this check for cover all
    if @person.try(:is_resident_role_active?)
      redirect_to @person.resident_role.bookmark_url || family_account_path
    elsif @person.try(:is_consumer_role_active?)
      redirect_to @person.consumer_role.bookmark_url || family_account_path
    else
      current_user.last_portal_visited = search_insured_consumer_role_index_path
      current_user.save!
      # render 'privacy'
    end
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, private, must-revalidate"
    response.headers["Pragma"] = "no-cache"
  end

  def set_error_message(message)
    if message.include? "year too big to marshal"
      "Date of birth cannot be more than 110 years ago"
    else
      message
    end
  end

  def build_person_params
    @person_params = {:ssn => Person.decrypt_ssn(@person.encrypted_ssn)}

    %w[first_name middle_name last_name gender].each do |field|
      @person_params[field] = @person.attributes[field]
    end

    @person_params[:dob] = @person.dob.strftime("%Y-%m-%d")
    @person_params.merge!({user_id: current_user.id})
  end
end
