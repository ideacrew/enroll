class DocumentsController < ApplicationController
  helper_method :sort_filter, :sort_direction
  before_action :set_document, only: [:destroy, :update, :comment]
  respond_to :html, :js

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    send_data Aws::S3Storage.find(uri), get_options(params)
  end

  def update_individual
    person = Person.find(params[:person_id])
    person.consumer_role.import! verification_attr
    respond_to do |format|
      format.html { redirect_to :back }
    end
  end

  def show_docs
    if current_user.has_hbx_staff_role?
      session[:person_id] = params[:person_id]
      set_current_person
    end
    redirect_to verification_insured_families_path
  end

  def destroy
    @document.delete
    respond_to do |format|
      format.html { redirect_to verification_insured_families_path }
      format.js
    end

  end

  def update
    if params[:comment]
      @document.update_attributes(:status => params[:status], :comment => params[:person][:vlp_document][:comment])
    else
      @document.update_attributes(:status => params[:status])
    end
    respond_to do |format|
      format.html {redirect_to verification_insured_families_path, notice: "Document Status Updated"}
      format.js
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

  def set_document
    @person = Person.find(params[:person_id])
    @document = @person.consumer_role.vlp_documents.find(params[:id])
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
        @unverified_persons=Person.unverified_persons.in('consumer_role.vlp_documents.status':['downloaded']).order_by(sort_filter => sort_direction).page(params[:page]).per(20)
      when 'no_docs_uloaded'
        @unverified_persons=Person.unverified_persons.where('consumer_role.vlp_documents.status': 'not submitted').order_by(sort_filter => sort_direction).page(params[:page]).per(20)
      else
        @unverified_persons=Person.unverified_persons.order_by(sort_filter => sort_direction).page(params[:page]).per(20)
    end
  end

  def verification_attr
    OpenStruct.new({
       :vlp_verified_at => Time.now,
       :vlp_authority => "hbx",
       :citizen_status => params[:citizenship]
                   })
  end

end
