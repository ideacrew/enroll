# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    module OrganizationForms
      # Form object for phone, used exclusively in the broker agency profile
      class PhoneForm
        include Virtus.model
        include ActiveModel::Validations
        include ::L10nHelper

        attribute :id, String
        attribute :kind, String
        attribute :area_code, String
        attribute :number, String
        attribute :extension, String
        attribute :full_number_without_extension, String
        attribute :office_kind_options, Array

        validates_presence_of :kind, :area_code, :number

        # ensure_valid_phone_number will validate the phone number (both area code and number) when bs4_broker_flow is enabled
        # for this reason, these validations can be skipped when bs4_broker_flow is enabled
        validates :area_code,
                  unless: ->(_object) { EnrollRegistry.feature_enabled?(:bs4_broker_flow) },
                  numericality: true,
                  length: { minimum: 3, maximum: 3, message: "%{value} is not a valid area code" },
                  allow_blank: false

        validates :number,
                  unless: ->(_object) { EnrollRegistry.feature_enabled?(:bs4_broker_flow) },
                  numericality: true,
                  length: { minimum: 7, maximum: 7, message: "%{value} is not a valid phone number" },
                  allow_blank: false

        validate :ensure_valid_phone_number

        def initialize(attributes = {})
          attributes = sanitize_attributes(attributes) if EnrollRegistry.feature_enabled?(:bs4_broker_flow)

          super(attributes)
        end

        def persisted?
          false
        end

        def number=(val)
          number = val&.gsub("-", "")
          super number
        end

        def sanitize_attributes(attributes)
          if attributes['full_number_without_extension']&.present?
            number_without_extension = attributes['full_number_without_extension'].gsub(/\D/,'')
            attributes['area_code'] = number_without_extension.slice(0..2)
            attributes['number'] = number_without_extension.slice(3..9)

          elsif attributes['area_code']&.present? && attributes['number']&.present?
            attributes['full_number_without_extension'] = attributes['area_code'] + attributes['number']
          end

          attributes
        end

        def ensure_valid_phone_number
          return true unless EnrollRegistry.feature_enabled?(:bs4_broker_flow)
          number = self&.full_number_without_extension&.gsub(/\D/,'')

          errors.add(:base, l10n('phone_number.error')) unless (/\A\d{10}\z/).match?(number)
        end
      end
    end
  end
end
