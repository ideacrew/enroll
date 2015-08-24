class Insured::VerificationDocumentsController < ApplicationController
  before_action :get_family

  def upload
    @consumer_wrapper = Forms::ConsumerRole.new(person_consumer_role)

    if params.require(:consumer_role).permit![:file]
      doc_id = Aws::S3Storage.save(file_path, 'dchbx-id-verification')

      if doc_id.present?
        doc = build_document(doc_id, file_path)
        if save_consumer_role(doc)
          flash[:notice] = "File Saved"
        else
          flash[:error] = "Could not save file"
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
    params.require(:consumer_role).permit(:file)[:file].tempfile.path
  end

  def build_document(doc_id, file_path)
    @person.consumer_role.documents.build({
                                              identifier: doc_id,
                                              subject: params[:consumer_role][:vlp_document_kind],
                                              tags: [params[:consumer_role][:doc_number]] ,
                                              title: params[:consumer_role][:file].original_filename,
                                              format: params[:consumer_role][:file].content_type
                                          })
  end

  def save_consumer_role(doc)
    doc.save && @person.consumer_role.save
  end
end
