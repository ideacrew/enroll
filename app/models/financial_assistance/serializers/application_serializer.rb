# frozen_string_literal: true

module FinancialAssistance
  module Serializers
    class ApplicationSerializer < ::ActiveModel::Serializer
      attributes :id, :is_requesting_voter_registration_application_in_mail, :years_to_renew,
                 :parent_living_out_of_home_terms

      has_many :applicants, serializer: ::FinancialAssistance::Serializers::ApplicantSerializer

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?

        end
        hash
      end
    end
  end
end
