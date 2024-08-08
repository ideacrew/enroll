class PeopleController < ApplicationController
  include ApplicationHelper
  include ErrorBubble
  include VlpDoc

  before_action :sanitize_contact_method, only: [:update]
  before_action :set_requested_record, except: [:index]

  def update
    authorize record, :can_update?
    @person_old_home_address = @person.addresses.select{|address| address.kind == 'home'}.first.dup
    @family = @person.primary_family

    @person.updated_by = current_user.oim_id unless current_user.nil?
    valid_referer_component = "insured/families/#{params[:bs4] == 'true' ? 'manage_family' : 'personal'}"
    if @person.is_consumer_role_active? && request.referer.include?(valid_referer_component)
      @valid_vlp = update_vlp_documents(@person.consumer_role, 'person')
      redirect_path = personal_insured_families_path
    else
      redirect_path = family_account_path
    end
    @person.consumer_role.update_is_applying_coverage_status(person_params[:is_applying_coverage]) if @person.is_consumer_role_active?
    @native_status_changed = native_status_changed?(@person.consumer_role)
    respond_to do |format|
      if @valid_vlp != false && @person.update_attributes(person_params.except(:is_applying_coverage))
        if @person.is_consumer_role_active? && person_params[:is_applying_coverage] == "true"
          @person.consumer_role.check_native_status(@family, @native_status_changed)
        end
        @person.consumer_role.update_attribute(:is_applying_coverage, person_params[:is_applying_coverage]) if @person.consumer_role.present? && (!person_params[:is_applying_coverage].nil?)
        # if dual role, this will update both ivl and ee
        @person.active_employee_roles.each { |role| role.update_attributes(contact_method: person_params[:consumer_role_attributes][:contact_method]) } if @person.has_multiple_roles?
        if params[:page].eql? "from_registration"
          format.js
          format.html{redirect_back(fallback_location: root_path)}
        else
          format.html { redirect_to redirect_path, notice: 'Person was successfully updated.' }
          format.json { head :no_content }
        end
        @person_new_home_address = @person.addresses.select{|address| address.kind == 'home'}.first
        fm_count = @person&.primary_family&.family_members&.count
        update_dependent_addresses if fm_count && fm_count > 1
      else
        if @person.is_consumer_role_active?
          bubble_consumer_role_errors_by_person(@person)
          @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@person.consumer_role)
        end
        build_nested_models
        person_error_megs = @person.errors.full_messages.join('<br/>') if @person.errors.present?
        format.html { redirect_to redirect_path, alert: "Person update failed. #{person_error_megs}" }
        # format.html { redirect_to edit_insured_employee_path(@person) }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    authorize record, :can_show?
    # when we were doing cleanup on feb 2024 I was not able to delete :show because it was still used on specs
    # and referenced on some links, however, the next method find_all_by_person, doesnt exist anymore on EmployerProfile
    # that means :show is broken from the last 9 years
    # @employer_profile= EmployerProfile.find_all_by_person(@person).first
    # we need to do a deeper dive on why we are referencing :show and see if we can remove it

    build_nested_models
  end

  private

  def set_requested_record
    @person = find_person(params[:id])
  end

  def record
    @person
  end

  def safe_find(klass, id)
    begin
      klass.find(id)
    rescue
      nil
    end
  end

  def find_person(id)
    safe_find(Person, id)
  end

  def find_organization(id)
    safe_find(Organization, id)
  end

  def find_hbx_enrollment(id)
    safe_find(HbxEnrollment, id)
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

  def update_dependent_addresses
    dependents = @person.primary_family.family_members.reject(&:is_primary_applicant?)
    dependents.each do |dep|
      dependent_same_address_as_primary(dep)
    end
  end

  def dependent_same_address_as_primary(dependent)
    dep_address = dependent.person.addresses.select{|address| address.kind == 'home'}.first

    return unless @person_old_home_address.same_address?(dep_address)
    dep_address.address_1 = @person_new_home_address.address_1
    dep_address.address_2 = @person_new_home_address.address_2
    dep_address.address_3 = @person_new_home_address.address_3
    dep_address.city = @person_new_home_address.city
    dep_address.state = @person_new_home_address.state
    dep_address.zip = @person_new_home_address.zip
    dep_address.county = @person_new_home_address.county if @person_new_home_address.county.present?
    dep_address.save!
    dependent.person.save!
  end

  def sanitize_person_params
    if person_params["addresses_attributes"].present?
      person_params["addresses_attributes"].each do |key, address|
        if address["city"].blank? && address["zip"].blank? && address["address_1"].blank? && address['state']
          params["person"]["addresses_attributes"].delete("#{key}")
        end
      end
    end

    if person_params["phones_attributes"].present?
      person_params["phones_attributes"].each do |key, phone|
        if phone["full_phone_number"].blank?
          params["person"]["phones_attributes"].delete("#{key}")
        end
      end
    end

    if person_params["emails_attributes"].present?
      person_params["emails_attributes"].each do |key, email|
        if email["address"].blank?
          params["person"]["emails_attributes"].delete("#{key}")
        end
      end
    end
  end

  def person_params
    params.require(:person).permit(*person_parameters_list)
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
      { :consumer_role_attributes => [:contact_method, :language_preference, :id]},
      { :employee_roles_attributes => [:id, :contact_method, :language_preference]},

      :first_name,
      :middle_name,
      :last_name,
      :name_sfx,
      :gender,
      :us_citizen,
      :is_incarcerated,
      :language_code,
      :is_disabled,
      :race,
      :is_consumer_role,
      :is_resident_role,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      {:immigration_doc_statuses => []},
      {:ethnicity => []},
      :tribal_id,
      :tribal_state,
      :tribal_name,
      { :tribe_codes => [] },
      :no_dc_address,
      :is_homeless,
      :is_temporarily_out_of_state,
      :id,
      :consumer_role,
      :is_applying_coverage,
      :age_off_excluded,
      :is_tobacco_user
    ]
  end


end
