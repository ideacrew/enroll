module BenefitSponsors
  module Locations
    class OfficeLocation
      include Mongoid::Document

      embedded_in :profile, class_name: "BenefitSponsors::Organizations::Profile"

      field :is_primary, type: Boolean, default: true

      embeds_one :address, class_name:"BenefitSponsors::Locations::Address", cascade_callbacks: true, validate: true
      accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true
      embeds_one :phone, class_name:"BenefitSponsors::Locations::Phone", cascade_callbacks: true, validate: true
      accepts_nested_attributes_for :phone, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :address, class_name:"BenefitSponsors::Locations::Address"
      validates_presence_of :phone, class_name:"BenefitSponsors::Locations::Phone", if: :primary_or_branch?

      alias_method :is_primary?, :is_primary

      def county
        address.present? ? address.county : ""
      end

      def zip
        address.present? ? address.zip : ""
      end

      def primary_or_branch?
        ['primary', 'branch'].include? address.kind if address.present?
      end

      def address_can_be_rejected?
        attributes["address"].blank? || attributes["address"]["zip"].blank?
      end

      def phone_can_be_rejected?
        attributes["phone"].blank? || attributes["phone"]["number"].blank?
      end
    end
  end
end
