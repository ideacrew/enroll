class DocumentsController < ApplicationController
  before_action :set_doc, only: [:change_doc_status, :change_person_aasm_state]
  respond_to :html, :js

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    send_data Aws::S3Storage.find(uri), get_options(params)
  end

  def consumer_role_status
    @unverified_persons=Person.in(:'consumer_role.aasm_state'=>['verifications_outstanding', 'verifications_pending']).order_by(:created_at => 'asc').page(params[:page]).per(20)
    respond_to do |format|
      format.html { render partial: "index_consumer_role_status" }
      format.js {}
    end
  end

 def index
   @person = Person.find(params[:person_id])
   @person_documents = @person.consumer_role.vlp_documents
   mark_as_reviewed
 end

 def new_comment
   @person = Person.find(params[:person_id])
   @document = @person.consumer_role.vlp_documents.where(id: params[:doc_id]).first
 end

 def update
   @person = Person.find(params[:person][:id])
   @document = @person.consumer_role.vlp_documents.where(id: params[:person][:vlp_document][:id]).first
   @document.update_attributes(:comment => params[:person][:vlp_document][:comment])
 end

 def mark_as_reviewed
   @person_documents.each do |doc|
     if doc.status && doc.status == "downloaded"
       doc.status = "in review"
       doc.save
     end
   end
 end

 def change_doc_status
   @document.update_attributes(:status => params[:status])
   respond_to do |format|
          format.html {redirect_to documents_path(:person_id => @doc_owner.id), notice: "Document Status Updated"}
          end
 end



def change_person_aasm_state
  @doc_owner.consumer_role.update_attributes(:aasm_state => params[:state])
  respond_to do |format|
         format.html {redirect_to exchanges_hbx_profiles_root_path, notice: "Person Verification Status Updated"}
         end

end

 private
 def get_options(params)
   options = {}
   options[:content_type] = params[:content_type] if params[:content_type]
   options[:filename] = params[:filename] if params[:filename]
   options[:disposition] = params[:disposition] if params[:disposition]
   options
 end

 def set_doc
  @doc_owner = Person.where(id: params[:person_id]).first
  @document = @doc_owner.consumer_role.vlp_documents.where(id: params[:doc_id]).first
 end

end
