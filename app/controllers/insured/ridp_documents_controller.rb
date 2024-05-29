class Insured::RidpDocumentsController < ApplicationController
  include ApplicationHelper

  before_action :get_person
  before_action :check_for_consumer_role
  before_action :set_document,  only: [:destroy]
  before_action :enable_bs4_layout if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)

  def upload
    consumer_role = person_consumer_role
    authorize consumer_role, :ridp_document_upload?

    @doc_errors = []
    @docs_owner = @person

    if params[:file].blank?
      flash[:error] = "File not uploaded. Please select the file to upload."
    elsif !valid_file_uploads?(params[:file], FileUploadValidator::VERIFICATION_DOC_TYPES)
      redirect_back fallback_location: '/'
      return
    else
      params[:file].each do |file|
        doc_uri = Aws::S3Storage.save(file_path(file), 'id-verification')
        if doc_uri.present?
          if update_ridp_documents(file_name(file), doc_uri) == true
            flash[:notice] = "File Saved"
          else
            flash[:error] = "Could not save file. #{@doc_errors&.join('. ')}"
            redirect_back fallback_location: '/'
            return
          end
        else
          flash[:error] = "Could not save file"
        end
      end
    end

    redirect_back fallback_location: '/'
  end

  def download
    consumer_role = person_consumer_role
    authorize consumer_role, :ridp_document_download?

    document = get_document(params[:key])
    if document.present?
      bucket = env_bucket_name('id-verification')
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{params[:key]}"
      send_data Aws::S3Storage.find(uri), download_options(document)
    else
      flash[:error] = "File does not exist or you are not authorized to access it."
      redirect_back fallback_location: '/'
    end
    ridp_docs_clean(@person)
  end

  def destroy
    consumer_role = person_consumer_role
    authorize consumer_role, :ridp_document_delete?

    @document.delete

    if @person.consumer_role.identity_validation == "pending"
      @person.consumer_role.update_attributes(identity_validation: "outstanding")
    elsif @person.consumer_role.application_validation == "pending"
      @person.consumer_role.update_attributes(application_validation: "outstanding")
    end

    respond_to do |format|
      format.js { render (@bs4 ? "destroy_updated" : "destroy") }
    end
  end

  private

  def updateable?
    authorize Family, :updateable?
  end

  def get_person
    set_current_person(required: true)
  end

  def person_consumer_role
    @person.consumer_role
  end

  def person_resident_role
    @person.resident_role
  end

  def file_path(file)
    file.tempfile.path
  end

  def file_name(file)
    file.original_filename
  end

  def set_document
    @document = @person.consumer_role.ridp_documents.find(params[:id])
  end

  def check_for_consumer_role
    @consumer_role = @person.consumer_role
    return if @consumer_role

    flash[:error] = "No consumer role exists, you are not authorized to upload documents"
    redirect_back fallback_location: '/'
  end

  def update_ridp_documents(title, file_uri)
    ridp_type = params[:ridp_verification_type]
    duplicate_document = @docs_owner.consumer_role.ridp_documents.where(:subject => title, :title => title).first
    new_document = duplicate_document.present? ? nil : @docs_owner.consumer_role.ridp_documents.build
    success = if duplicate_document.present?
                duplicate_document.update_attributes({:identifier => file_uri, :subject => title, :title => title, :status => "downloaded", :ridp_verification_type => ridp_type, :uploaded_at => TimeKeeper.date_of_record})
              else
                new_document.attributes = {:identifier => file_uri, :subject => title, :title => title, :status => "downloaded", :ridp_verification_type => ridp_type, :uploaded_at => TimeKeeper.date_of_record}
                new_document.save
              end
    if success
      person_consumer_role.mark_ridp_doc_uploaded(ridp_type)
      @docs_owner.save
    else
      @doc_errors = @docs_owner.consumer_role.ridp_documents.last.errors&.full_messages
    end
  end

  def get_document(key)
    @person.consumer_role.find_ridp_document_by_key(key)
  end

  def download_options(document)
    options = {}
    options[:content_type] = document.format
    options[:filename] = document.title
    options
  end

  def ridp_docs_clean(person)
    existing_documents = person.consumer_role.ridp_documents
    person_consumer_role = Person.find(person.id).consumer_role
    person_consumer_role.ridp_documents = []
    person_consumer_role.save
    person_consumer_role = Person.find(person.id).consumer_role
    person_consumer_role.ridp_documents = existing_documents.uniq
    person_consumer_role.save
  end


  def enable_bs4_layout
    @bs4 = true
  end
end
