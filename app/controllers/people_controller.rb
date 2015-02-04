class PeopleController < ApplicationController

  def new
    @person = Person.new
    build_nested_models
    # render action: "new", layout: "form"
  end

  # Uses identifying information to return single pre-existing Person instance if already in DB
  def match_person
    @person = Person.new(params[:person])

    matched_person = Person.match_by_id_info(@person)

    if matched_person.blank?
      # Preexisting Person not found, create new instance and return to complete form entry
      if @person.save
        format.json { render json: @person, status: :created, location: @person }
      else
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    else
      # Matched Person, autofill form with found attributes
      @person = matched_person
      build_nested_models
      format.json { render json: @matched_person, status: :matched, location: @person }
    end
  end

  # Uses identifying information to return one or more for matches in employer census
  def match_employer
  end

  def link_employer
  end

  def update
    @person = Person.find(params[:id])
    @person.updated_by = current_user.email unless current_user.nil?

    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @person = Person.new(person_params)
    
    respond_to do |format|
      if @person.save
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
        format.json { render json: @person, status: :created, location: @person }
      else
        format.html { render action: "new" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @person = Person.find(params[:id])
    build_nested_models
  end

private
  def build_nested_models
    @person.addresses.build if @person.addresses.empty?
    @person.phones.build if @person.phones.empty?
    @person.emails.build if @person.emails.empty?
  end
  
  def person_params
    params.require(:person).permit(:name_pfx, :first_name, :middle_name, :last_name, 
                                   :name_sfx, :name_full, :alternate_name, :ssn, :dob, 
                                   :gender, :date_of_death, :is_active, :subscriber_type,  
                                    addresses_attributes: [:kind, :address_1, :address_2, :address_3, :city, :county, :state, :location_state_code, :zip, :zip_extension, :country_name, :full_text ])
  end

end
