class DocumentsController < ApplicationController
  before_action :set_doc, only: [:change_doc_status]

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    if params[:contenttype] && params[:filename]
      send_data Aws::S3Storage.find(uri), :content_type => params[:contenttype], :filename => params[:filename]
    else
      send_data Aws::S3Storage.find(uri)
    end
  end

  def consumer_role_status
    @unverified_persons=Person.where(:'consumer_role.aasm_state'=>'verifications_pending').to_a
    respond_to do |format|
      format.html { render partial: "index_consumer_role_status" }
      format.js {}
    end
  end

 def documents_review
   @person = Person.find(params[:person_id])
   @person_documents = @person.consumer_role.vlp_documents
 end

 def change_doc_status
   @document.update_attributes(:status => params[:status])
   respond_to do |format|
          format.html {redirect_to documents_review_documents_path(:person_id => @doc_owner.id), notice: "Document Status Updated"}
          end
 end

 private

 def set_doc
  @doc_owner = Person.where(id: params[:person_id]).first
  @document = @doc_owner.consumer_role.vlp_documents.where(id: params[:doc_id]).first
 end

end
