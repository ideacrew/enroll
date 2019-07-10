# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class IssuerDatatableSerializer < ActiveModel::Serializer
      include FastJsonapi::ObjectSerializer
      extend ::ApplicationHelper
      attributes :legal_name, :phone, :email, :working_hours

      attribute(&:legal_name)

      attribute :phone do
        'N/A'
      end

      attribute :email do
        'N/A'
      end

      attribute :working_hours do
        'N/A'
      end
    end
  end
end
