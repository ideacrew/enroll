class Insured::VerificationDocumentsController < ApplicationController
  include ApplicationHelper

  before_action :get_family

  def upload
    @doc_errors = []
    doc_params = params_clean_vlp_documents

    if doc_params.empty?
      flash[:error] = "File not uploaded. Document type and/or document fields not provided "
      redirect_to(:back)
      return
    elsif params.permit![:file]
      doc_uri = Aws::S3Storage.save(file_path, 'dchbx-id-verification')

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

  def params_clean_vlp_documents
    return if params[:consumer_role].nil? or params[:consumer_role][:vlp_documents_attributes].nil?

    params[:consumer_role][:vlp_documents_attributes].reject! do |index, doc|
      params[:immigration_doc_type] != doc[:subject]
    end
  end

  def update_vlp_documents(doc_params, title, file_uri)
    return unless doc_params.present?
    document = find_document(@person.consumer_role, doc_params.first.last[:subject])
    success = document.update_attributes(doc_params.first.last.merge({:identifier=>file_uri, :title=>title}))
    @doc_errors = document.errors.full_messages unless success
    @person.save
  end
end
