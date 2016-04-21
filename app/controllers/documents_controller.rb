class DocumentsController < ApplicationController
  helper_method :sort_filter, :sort_direction
  before_action :set_doc, only: [:change_doc_status, :change_person_aasm_state]
  respond_to :html, :js

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    send_data Aws::S3Storage.find(uri), get_options(params)
  end

  def authorized_download
    begin
      model = params[:model].camelize
      model_id = params[:model_id]
      relation = params[:relation]
      relation_id = params[:relation_id]
      model_object = Object.const_get(model).find(model_id)
      documents = model_object.send(relation.to_sym)
      if authorized_to_download?(model_object, documents, relation_id)
        uri = documents.find(relation_id).identifier
        send_data Aws::S3Storage.find(uri), get_options(params)
      else
       raise "Sorry! You are not authorized to download this document."
      end
    rescue => e
      redirect_to(:back, :flash => {error: e.message})
    end
  end

  def consumer_role_status
    docs_page_filter
    search_box
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

 def sort_filter
   %w(first_name last_name created_at).include?(params[:sort]) ? params[:sort] : 'created_at'
 end

 def sort_direction
   %w(asc desc).include?(params[:direction]) ? params[:direction] : 'desc'
 end

 def search_box
   if params[:q]
     @q = params[:q]
     @unverified_persons = @unverified_persons.search(params[:q])
   end
 end

 def docs_page_filter
   case params[:sort]
     when 'waiting'
       @unverified_persons=Person.unverified_persons.in('consumer_role.vlp_documents.status':['downloaded', 'in review']).order_by(sort_filter => sort_direction).page(params[:page]).per(20)
     when 'no_docs_uloaded'
       @unverified_persons=Person.unverified_persons.where('consumer_role.vlp_documents.status': 'not submitted').order_by(sort_filter => sort_direction).page(params[:page]).per(20)
     else
       @unverified_persons=Person.unverified_persons.order_by(sort_filter => sort_direction).page(params[:page]).per(20)
   end
 end

  def authorized_to_download?(owner, documents, document_id)
    return true
    owner.user.has_hbx_staff_role? || documents.find(document_id).present?
  end
end
