class Insured::VerificationDocumentsController < ApplicationController
  include ApplicationHelper

  before_action :get_family


  def upload
    @doc_errors = []
    doc_params = {:subject => params[:document]}
    @docs_owner = find_docs_owner(params[:family_member])


    if params.permit![:file]
      doc_uri = Aws::S3Storage.save(file_path, 'id-verification')

      if doc_uri.present?
        if update_vlp_documents(doc_params, file_name, doc_uri)
          flash[:notice] = "File Saved"
        else
          flash[:error] = "Could not save file. " + @doc_errors.join(". ")
          redirect_to(:back)
          return
        end
      else
        flash[:error] = "Could not save file"
      end
    else
      flash[:error] = "File not uploaded"
    end
    redirect_to documents_index_insured_families_path

  end

  def download
    document = get_document(params[:key])
    if document.present?
      bucket = env_bucket_name('id-verification')
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{params[:key]}"
      send_data Aws::S3Storage.find(uri), download_options(document)
    else
      flash[:error] = "File does not exist or you are not authorized to access it."
      redirect_to documents_index_insured_families_path
    end
  end

  private
  def get_family
    set_current_person
    @family = @person.primary_family
  end

  def person_consumer_role
    @person.consumer_role
  end

  def file_path
    params.permit(:file)[:file].tempfile.path
  end

  def file_name
    params.permit![:file].original_filename
  end

  def find_docs_owner(id)
    @person.primary_family.family_members.where(id:id).first.person
  end

  def update_vlp_documents(doc_params, title, file_uri)
    document = @docs_owner.consumer_role.find_document_to_download(doc_params[:subject])
    success = document.update_attributes(doc_params.merge({:identifier=>file_uri, :title=>title, :status=>"downloaded"}))
    @doc_errors = document.errors.full_messages unless success
    @docs_owner.save
  end

  def get_document(key)
    @person.consumer_role.find_vlp_document_by_key(key)
  end

  def download_options(document)
    options = {}
    options[:content_type] = document.format
    options[:filename] = document.title
    options
  end

end
