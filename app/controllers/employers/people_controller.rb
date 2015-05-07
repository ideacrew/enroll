class Employers::PeopleController < ApplicationController

  def search
    @person = Forms::EmployeeCandidate.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def match
    @employee_candidate = Forms::EmployeeCandidate.new(params.require(:person))
    if @employee_candidate.valid?
      found_person = @employee_candidate.match_person
      unless params["create_person"].present?
        if found_person.present?
          @person = found_person
          respond_to do |format|
            format.js { render 'match' }
            format.html { render 'match' }
          end
        else
          @person = Person.new
          build_nested_models
          respond_to do |format|
            format.js { render 'no_match' }
            format.html { render 'no_match' }
          end
        end
      else
        params.permit!
        @person = current_user.instantiate_person
        @person.attributes = params[:person]
        @person.build_employer_contact
        @employer_profile = @person.employer_contact
        @person.save
        build_nested_models
        respond_to do |format|
          format.js { render "edit" }
          format.html { render "edit" }
        end
      end
    else
      @person = @employee_candidate
      respond_to do |format|
        format.js { render 'search' }
        format.html { render 'search' }
      end
    end
  end

  def create
    @person = current_user.person.present? ? current_user.person : current_user.build_person
    @person.build_employer_contact
    @employer_profile = @person.employer_contact
    build_nested_models
    respond_to do |format|
      format.js { render "edit" }
      format.html { render "edit" }
    end
  end

  def update
    sanitize_person_params
    @person = Person.find(params[:id])
    make_new_person_params @person

    @person.addresses.each {|address| address.delete}
    @person.phones.each {|phone| phone.delete}
    @person.emails.each {|email| email.delete}

    @employer_profile = @person.employer_contact.present? ? @person.employer_contact : @person.build_employer_contact

    @person.updated_by = current_user.email unless current_user.nil?
    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.js { render "employer_form" }
        format.html { render "employer_form" }
      else
        build_nested_models
        format.html { render action: "show" }
        # format.html { redirect_to edit_consumer_employee_path(@person) }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  private

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

  def person_params
    params.require(:person).permit!
  end

end