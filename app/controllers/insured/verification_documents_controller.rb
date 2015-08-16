class Insured::VerificationDocumentsController < ApplicationController
  before_action :get_family

  def upload
    @consumer_wrapper = Forms::ConsumerRole.new(@person.consumer_role)
    @consumer_wrapper.create_document(params.require(:consumer_role).permit(:file)[:file].tempfile.path)

    #more stuff

    #redirect/render?
  end

  private
    def get_family
      set_current_person
      @family = @person.primary_family
    end
end
