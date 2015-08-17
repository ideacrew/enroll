class Insured::VerificationDocumentsController < ApplicationController
  before_action :get_family

  def upload
    @consumer_wrapper = Forms::ConsumerRole.new(@person.consumer_role)

    if params[:file]
      doc_id = Aws::S3Storage.save(params.require(:consumer_role).permit(:file)[:file].tempfile.path, 'dchbx-id-verification')

      if doc_id.present?
        @person.consumer_role.documents.build({
          identifier: doc_id,
          subject: @consumer_wrapper.kind,
          relation: @consumer_wrapper.doc_number,
          title: params.require(:consumer_role).permit(:file)[:file].original_filename
          })
        if @person.consumer_role.save
          redirect_to documents_index_insured_families_path
        else
          flash[:error] = "could not save file"
          redirect_to documents_index_insured_families_path
        end
      end
    end

  end

  private
    def get_family
      set_current_person
      @family = @person.primary_family
    end
end
