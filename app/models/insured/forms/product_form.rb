# frozen_string_literal: true

module Insured
  module Forms
    class ProductForm
      include Virtus.model

      attribute :id,                    String
      attribute :application_period,    Date
      attribute :kind,                  Symbol
      attribute :title,                 String
      attribute :hios_id,               String
      attribute :issuer_profile_id,     String
      attribute :issuer_legal_name,     String
      attribute :issuer_hios_id,        String
      attribute :metal_level_kind,      String
      attribute :sbc_document,          ::Insured::Forms::SbcDocumentForm


      def active_year
        application_period.min.year
      end

      def get_carrier_logo
        issuer = ::BenefitSponsors::Organizations::IssuerProfile.find(BSON::ObjectId.from_string(self.issuer_profile_id))

        return '' if issuer.legal_name.nil?
        Settings.aca.carrier_hios_logo_variant[self.hios_id[0..4]] || issuer.legal_name
      end

      def display_carrier_logo(options = {:width => 50})
        carrier_name = get_carrier_logo
        return "<img src=\"\/assets\/logo\/carrier\/#{carrier_name.parameterize.underscore}.jpg\" width=\"50\"/>"
      end

      def render_product_type_details
        product_details = []

        if product_level = self.metal_level_kind.try(:humanize)
          product_details << "<span class=\"#{product_level.try(:downcase)}-icon\">#{self.metal_level_kind.titleize}</span>"
        end

        if self.try(:nationwide)
          product_details << "NATIONWIDE NETWORK"
        end

        product_details.inject([]) do |data, element|
          data << "#{element}"
        end.join("&nbsp<label class='separator'></label>").html_safe
      end
    end
  end
end
