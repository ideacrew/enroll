class Insured::ConsumerRolesController < ApplicationController
  include ApplicationHelper
  before_action :check_consumer_role, only: [:search]

  before_action :find_consumer_role_and_person, only: [:edit, :update]

  def search
    @help_me = true
    @person = Forms::ConsumerCandidate.new
    respond_to do |format|
      format.html
    end
  end

  def match
    @person_params = params.require(:person).merge({user_id: current_user.id})
    @consumer_candidate = Forms::ConsumerCandidate.new(@person_params)
    @person = @consumer_candidate
    respond_to do |format|
      if @consumer_candidate.valid?
        idp_search_result = nil
        if current_user.idp_verified?
          idp_search_result = :not_found
        else
          idp_search_result = IdpAccountManager.check_existing_account(@consumer_candidate)
        end
        case idp_search_result
        when :service_unavailable
          format.html { render 'idp_unavailable' }
        when :too_many_matches
          format.html { render 'idp_identity_conflict' }
        when :existing_account
          format.html { render 'redirect_to_recover_account' }
        else
          found_person = @consumer_candidate.match_person
          if found_person.present?
            format.html { render 'match' }
          else
            format.html { render 'no_match' }
          end
        end
      else
        format.html { render 'search' }
      end
    end
  end

  def create
    @consumer_role = Factories::EnrollmentFactory.construct_consumer_role(params.permit!, actual_user)
    @person = @consumer_role.person
    idp_account_created = nil
    if current_user.idp_verified?
      idp_account_created = :created
    else
      idp_account_created = IdpAccountManager.create_account(current_user.email, stashed_user_password, @person, 15)
    end
    case idp_account_created
    when :created
      session[:person_id] = @person.id
      session.delete("stashed_password")
      respond_to do |format|
        format.html { redirect_to :action => "edit", :id => @consumer_role.id }
      end
    else
      respond_to do |format|
        format.html { render 'idp_unavailable' }
      end
    end
  end

  def edit
    build_nested_models
  end

  def update
    @person.addresses = []
    @person.phones = []
    @person.emails = []

    params_clean_vlp_documents
    update_vlp_documents
    if @person.update_attributes(params.require(:person).permit(*person_parameters_list))
      redirect_to ridp_agreement_insured_consumer_role_index_path
    else
      build_nested_models
      respond_to do |format|
        format.html { render "edit" }
      end
    end
  end

  def ridp_agreement
  end

  private

  def person_parameters_list
    [
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip] },
      { :phones_attributes => [:kind, :full_phone_number] },
      { :emails_attributes => [:kind, :address] },
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
      :ethnicity,
      :us_citizen,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      :tribal_id,
      :no_dc_address,
      :no_dc_address_reason
    ]
  end

  def build_nested_models
    ["home", "mobile"].each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select { |phone| phone.kind == kind }.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select { |address| address.kind.to_s.downcase == kind }.blank?
    end

    Email::KINDS.each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select { |email| email.kind == kind }.blank?
    end
  end

  def find_consumer_role_and_person
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
  end

  def params_clean_vlp_documents
    return if params[:person][:consumer_role_attributes].nil? || params[:person][:consumer_role_attributes][:vlp_documents_attributes].nil?

    if params[:person][:us_citizen].eql? 'true'
      params[:person][:consumer_role_attributes][:vlp_documents_attributes].reject! do |index, doc|
        params[:naturalization_doc_type] != doc[:subject]
      end
    elsif params[:person][:eligible_immigration_status].eql? 'true'
      params[:person][:consumer_role_attributes][:vlp_documents_attributes].reject! do |index, doc|
        params[:immigration_doc_type] != doc[:subject]
      end
    end
  end

  def update_vlp_documents
    return if params[:person][:consumer_role_attributes].nil? || params[:person][:consumer_role_attributes][:vlp_documents_attributes].nil? || params[:person][:consumer_role_attributes][:vlp_documents_attributes].first.nil?
    doc_params = params.require(:person).permit({:consumer_role_attributes =>
                                                 [:vlp_documents_attributes =>
                                                  [:subject, :citizenship_number, :naturalization_number,
                                                   :alien_number, :passport_number, :sevis_id, :visa_number,
                                                   :receipt_number, :expiration_date, :card_number, :i94_number]]})
    document = find_document(@consumer_role, doc_params[:consumer_role_attributes][:vlp_documents_attributes].first.last[:subject])
    document.update_attributes(doc_params[:consumer_role_attributes][:vlp_documents_attributes].first.last)
    document.save
  end

  def check_consumer_role
    if current_user.has_consumer_role?
      redirect_to family_account_path
    else
      current_user.last_portal_visited = search_insured_consumer_role_index_path
      current_user.save!
    end
  end

  def stashed_user_password
    session["stashed_password"]
  end
end
