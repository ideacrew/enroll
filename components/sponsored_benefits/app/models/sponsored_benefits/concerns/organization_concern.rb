require 'active_support/concern'

module SponsoredBenefits
  module Concerns::OrganizationConcern
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id, type: String

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Federal Employer ID Number
      field :fein, type: String

      field :entity_kind, type: String

      # Web URL
      field :home_page, type: String

      field :is_active, type: Boolean

      field :is_fake_fein, type: Boolean

      # User or Person ID who created/updated
      field :updated_by, type: BSON::ObjectId

      embeds_many :office_locations, class_name: "SponsoredBenefits::Organizations::OfficeLocation", cascade_callbacks: true, validate: true

      accepts_nested_attributes_for :office_locations, class_name: "SponsoredBenefits::Organizations::OfficeLocation", allow_destroy: true

      validates_presence_of :legal_name, :office_locations

      # validates :fein,
      #   presence: false,
      #   length: { is: 9, message: "%{value} is not a valid FEIN" },
      #   numericality: true,
      #   uniqueness: true

      validate :office_location_kinds

      index({ hbx_id: 1 }, { unique: true })
      index({ legal_name: 1 })
      index({ dba: 1 }, {sparse: true})
      index({ fein: 1 }, { unique: true })
      index({ is_active: 1 })

      before_save :generate_hbx_id
      after_update :legal_name_or_fein_change_attributes,:if => :check_legal_name_or_fein_changed?

      def generate_hbx_id
        write_attribute(:hbx_id, SponsoredBenefits::Organizations::HbxIdGenerator.generate_organization_id) if hbx_id.blank?
      end

      def office_location_kinds
        location_kinds = self.office_locations.reject(&:persisted?).flat_map(&:address).compact.flat_map(&:kind)

        return if location_kinds.empty? && office_locations.select(&:marked_for_destruction?).count < 1
        return errors.add(:base, 'must select one primary address') if primary_office_size < 1
        return errors.add(:base, "can't have multiple primary addresses") if primary_office_size > 1
        return errors.add(:base, "can't have more than one mailing address") if mailing_office_size > 1

        # should validate only office location which are not persisted AND kinds ie. primary, mailing, branch
        return if location_kinds.detect {|kind| kind == 'work' || kind == 'home'}
      end

      def primary_office_size
        primary_count = office_locations.select {|o| o.address.kind == 'primary'}.count
        primary_destroy_count = office_locations.select {|o| o.marked_for_destruction? && o.address.kind == 'primary'}.count
        primary_count - primary_destroy_count
      end

      def mailing_office_size
        mailing_count = office_locations.select {|o| o.address.kind == 'mailing'}.count
        mailing_destroy_count = office_locations.select {|o| o.marked_for_destruction? && o.address.kind == 'mailing'}.count
        mailing_count - mailing_destroy_count
      end

      def check_legal_name_or_fein_changed?
        fein_changed? || legal_name_changed?
      end

      def legal_name_or_fein_change_attributes
        @changed_fields = changed_attributes.keys
        notify_legal_name_or_fein_change if changed_attributes.keys.include?("fein")
      end

      def notify_legal_name_or_fein_change
        return unless self.employer_profile.present?
        FIELD_AND_EVENT_NAMES_MAP.each do |feild, event_name|
          if @changed_fields.present? && @changed_fields.include?(feild)
            notify("acapi.info.events.employer.#{event_name}", {employer_id: self.hbx_id, event_name: "#{event_name}"})
          end
        end
      end

      def office_location_county
        primary_office_location.county
      end

      def office_location_zip
        primary_office_location.zip
      end

      def primary_office_location
        office_locations.detect(&:is_primary?)
      end
    end

    class_methods do
      PROFILE_KINDS = [:plan_design_profile, :employer_profile, :broker_agency_profile, :general_agency_profile]
      ENTITY_KINDS = [
        "tax_exempt_organization",
        "c_corporation",
        "s_corporation",
        "partnership",
        "limited_liability_corporation",
        "limited_liability_partnership",
        "household_employer",
        "governmental_employer",
        "foreign_embassy_or_consulate"
      ]

      FIELD_AND_EVENT_NAMES_MAP = {"legal_name" => "name_changed", "fein" => "fein_corrected"}
    end
  end
end
