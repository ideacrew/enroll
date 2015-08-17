class Consumer::ConsumerRolesController < ApplicationController

  def new
    @person = current_user.build_person
    build_nested_models
  end

  def create
    @person = Person.match_by_id_info(params[:person]).first
    @person = Person.new(params[:person].except(:user_id).permit!) unless @person.present?
    @consumer_role = @person.build_consumer_role(is_applicant: true)
    @person.save

    respond_to do |format|
      format.html { redirect_to :action => "edit", :id => @consumer_role.id }
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
      if params[:tribal_document]
        doc_id = Aws::S3Storage.save(params[:tribal_document].tempfile.path, 'dchbx-id-verification')
        @consumer_role.documents.build({identifier: doc_id, title: params[:tribal_document].original_filename}) if doc_id
        @consumer_role.save!
      end
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
    Phone::KINDS.delete_if { |kind| kind == "work" }.each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select { |phone| phone.kind == kind }.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select { |address| address.kind.to_s.downcase == kind }.blank?
    end

    Email::KINDS.each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select { |email| email.kind == kind }.blank?
    end
  end
end
