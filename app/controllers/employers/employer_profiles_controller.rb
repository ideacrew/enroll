class Employers::EmployerProfilesController < ApplicationController
  before_action :find_employer, only: [:show, :destroy]
  before_action :check_employer_role, only: [:new, :welcome]

  def index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:page)[:page]
    page_no = page_string.blank? ? nil : page_string.to_i
    @organizations = Organization.search(@q).exists(employer_profile: true).page page_no
    @employer_profiles = @organizations.map {|o| o.employer_profile}
  end

  def welcome
  end


  def person_search
    @person = Forms::EmployeeCandidate.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def person_match
    @employee_candidate = Forms::EmployeeCandidate.new(params.require(:person))
    if @employee_candidate.valid?
      found_person = @employee_candidate.match_person
      if found_person.present?
        @person = found_person
        respond_to do |format|
          format.js { render 'person_match' }
          format.html { render 'person_match' }
        end
      else
        respond_to do |format|
          format.js { render 'no_match' }
          format.html { render 'no_match' }
        end
      end
    else
      @person = @employee_candidate
      respond_to do |format|
        format.js { render 'person_search' }
        format.html { render 'person_search' }
      end
    end
  end

  def search
    @employer_profile = Forms::EmployerCandidate.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def match
    @employer_candidate = Forms::EmployerCandidate.new(params.require(:employer_profile))
    if @employer_candidate.valid?
      found_employer = @employer_candidate.match_employer
      if found_employer.present?
        @employer_profile = found_employer
        respond_to do |format|
          format.js { render 'match' }
          format.html { render 'match' }
        end
      else
        respond_to do |format|
          format.js { render 'no_match' }
          format.html { render 'no_match' }
        end
      end
    else
      @employer_profile = @employer_candidate
      respond_to do |format|
        format.js { render 'search' }
        format.html { render 'search' }
      end
    end
  end

  def my_account
  end

  def show
    @current_plan_year = @employer_profile.plan_years.last
    @benefit_groups = @current_plan_year.benefit_groups if @current_plan_year.present?
  end

  def new
    @organization = build_employer_profile
  end

  def person_create
    # binding.pry
    @person = current_user.person.present? ? current_user.person : current_user.build_person
    # @person = current_user.person
    @person.build_employer_contact
    @employer_profile = @person.employer_contact
    build_nested_models
    respond_to do |format|
      format.js { render "edit" }
      format.html { render "edit" }
    end
  end

  def person_update
    sanitize_person_params
    @person = Person.find(params[:id])

    make_new_person_params @person

    # Delete old sub documents
    @person.addresses.each {|address| address.delete}
    @person.phones.each {|phone| phone.delete}
    @person.emails.each {|email| email.delete}

    @person.updated_by = current_user.email unless current_user.nil?
    # fail
    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to employers_employer_profile_path(@person), notice: 'Person was successfully updated.' }
        format.json { head :no_content }
      else
        build_nested_models
        format.html { render action: "show" }
        # format.html { redirect_to edit_consumer_employee_path(@person) }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # def create
  #   @organization = Organization.new
  #   @organization.build_employer_profile
  #   @organization.attributes = employer_profile_params
  #   if @organization.save
  #     flash[:notice] = 'Employer successfully created.'
  #     redirect_to employers_employer_profiles_path
  #   else
  #     render action: "new"
  #   end
  # end

  def destroy
    @employer_profile.destroy

    respond_to do |format|
      format.html { redirect_to employers_employer_index_path, notice: "Employer successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    def check_employer_role
      if current_user.has_employer_role?
        redirect_to employers_employer_profile_my_account_path(current_user.person.employer_contact)
      end
    end

    def find_employer
      id_params = params.permit(:id, :employer_profile_id)
      id = id_params[:id] || id_params[:employer_profile_id]
      @employer_profile = EmployerProfile.find(id)
    end

    def employer_profile_params
      params.require(:organization).permit(
        :employer_profile_attributes => [ :entity_kind, :dba, :fein, :legal_name],
        :office_locations_attributes => [
          :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
          :phone_attributes => [:kind, :area_code, :number, :extension],
          :email_attributes => [:kind, :address]
        ]
      )
    end

    def build_employer_profile
      organization = Organization.new
      organization.build_employer_profile
      office_location = organization.office_locations.build
      office_location.build_address
      office_location.build_phone
      office_location.build_email
      organization
    end

    def build_nested_models
      ["home","mobile","work","fax"].each do |kind|
        @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
      end

      Address::KINDS.each do |kind|
        @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind == kind}.blank?
      end

      ["home","work"].each do |kind|
        @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
      end
    end

    def sanitize_person_params
      person_params["addresses_attributes"].each do |key, address|
        if address["city"].blank? && address["zip"].blank? && address["address_1"].blank?
          person_params["addresses_attributes"].delete("#{key}")
        end
      end

      person_params["phones_attributes"].each do |key, phone|
        if phone["full_phone_number"].blank?
          person_params["phones_attributes"].delete("#{key}")
        end
      end

      person_params["emails_attributes"].each do |key, email|
        if email["address"].blank?
          person_params["emails_attributes"].delete("#{key}")
        end
      end
    end

    def person_params
      params.require(:person).permit!
    end

    def make_new_person_params person

      # Delete old sub documents
      person.addresses.each {|address| address.delete}
      person.phones.each {|phone| phone.delete}
      person.emails.each {|email| email.delete}

      person_params["addresses_attributes"].each do |key, address|
        if address.has_key?('id')
          address.delete('id')
        end
      end

      person_params["phones_attributes"].each do |key, phone|
        if phone.has_key?('id')
          phone.delete('id')
        end
      end

      person_params["emails_attributes"].each do |key, email|
        if email.has_key?('id')
          email.delete('id')
        end
      end
    end

end
