# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class IssuerDatatableSerializer
      include FastJsonapi::ObjectSerializer
      attributes :legal_name

      attribute :phone do |object|
        retrieve_info(object.legal_name)[0]
      end

      attribute :email do |object|
        retrieve_info(object.legal_name)[1]
      end

      attribute :working_hours do |object|
        retrieve_info(object.legal_name)[2]
      end

      def self.retrieve_info(legal_name)
        {
          "Aetna" => ['1-855-586-6959', '', ''],
          "BestLife" => ['1-800-433-0088', '', ''],
          "CareFirst" => ['1-855-444-3119', '', ''],
          "Delta Dental" => ['1-800.872.0500', '', ''],
          "Dentegra" => ['1-800-471-0284', '', ''],
          "Dominion" => ['1-855-224-3016', '', ''],
          "Kaiser" => ['1-800-777-7902', '', ''],
          "MetLife" => ['1-855-638-2221', '', ''],
          "UnitedHealthcare" => ['1-888-842-4571', '', '']
        }[legal_name]
      end
    end
  end
end
