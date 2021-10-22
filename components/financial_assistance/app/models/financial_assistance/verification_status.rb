# frozen_string_literal: true

module FinancialAssistance
  #verification status for an applicant
  class VerificationStatus
    include Mongoid::Document
    include Mongoid::Timestamps


    field :status, type: String
    field :title, type: String
    field :description, type: String
    field :due_on, type: Date
    field :updated_by, type: String
    field :assigned_to, type: String


    embeds_many :documents, as: :documentable, class_name: '::FinancialAssistance::Document' do
      def uploaded
        @target.select(&:doc_identifier)
      end
    end
  end
end