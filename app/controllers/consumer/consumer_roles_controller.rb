class Consumer::ConsumerRolesController < ApplicationController

  def new
    @person = current_user.build_person
    build_nested_models
  end

  def create
    @person = Person.match_by_id_info(params[:person]).first
    @person = Person.new(params[:person].except(:user_id).permit!) unless @person.present?
    @person.build_consumer_role(is_applicant: true) unless @person.consumer_role.present?
    @person.save
    family,applicant = Factories::EnrollmentFactory.initialize_family(@person, [])
    family.save
    current_user.person = @person
    current_user.save

    respond_to do |format|
      format.html { redirect_to :action => "edit", :id => @person.consumer_role.id }
    end
  end

  def edit
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
    build_nested_models
  end

  def update
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
    @person.addresses = []
    @person.phones = []
    @person.emails = []
    if @person.update_attributes(params.require(:person).permit!)
      redirect_to new_insured_interactive_identity_verifications_path
    else
      build_nested_models
      respond_to do |format|
        format.html { render "edit" }
      end
    end
  end

  private
  def build_nested_models
    Phone::KINDS.delete_if{|kind| kind == "work"}.each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind.to_s.downcase == kind}.blank?
    end

    Email::KINDS.each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end
end
