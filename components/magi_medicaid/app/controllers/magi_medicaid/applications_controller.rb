# frozen_string_literal: true

module MagiMedicaid
  class ApplicationsController < MagiMedicaid::ApplicationController

    before_action :set_current_person

    layout "magi_medicaid_nav", only: %i[edit]

    require 'securerandom'

    def editI thin
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url

      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)
      #TODO: Need to set pattern for displaying support text without workflow controller.
    end

    def application_checklist
      @application = MagiMedicaid::Application.where(id: params[:id], family_id: get_current_person.financial_assistance_identifier).first
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url

      render layout: 'financial_assistance'
    end

    def checklist_pdf
      send_file(
          MagiMedicaid::Engine.root.join(MagiMedicaidRegistry[:magi_medicaid_documents].settings(:ivl_application_checklist).item.to_s), :disposition => "inline", :type => "application/pdf"
      )
    end
  end
end
