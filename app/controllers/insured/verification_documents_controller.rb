class Insured::VerificationDocumentsController < ApplicationController
  before_action :get_family

  def upload
    @consumer_wrapper = Forms::ConsumerRole.new(@person.consumer_role)


    if params.require(:consumer_role).permit![:file]
      doc_id = Aws::S3Storage.save(params.require(:consumer_role).permit(:file)[:file].tempfile.path, 'dchbx-id-verification')

      if doc_id.present?
        doc = @person.consumer_role.documents.build({
                                                  identifier: doc_id,
                                                  subject: @consumer_wrapper.kind,
                                                  relation: @consumer_wrapper.doc_number,
                                                  title: params.require(:consumer_role).permit(:file)[:file].original_filename
                                              })
        if doc.save && @person.consumer_role.save
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
end
