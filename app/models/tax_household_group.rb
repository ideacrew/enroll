# frozen_string_literal: true

# Persistence class to group TaxHouseholds on each financial assistance determination.
class TaxHouseholdGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  SOURCE_KINDS = %w[Curam Admin Renewals Faa Ffe].freeze

  embedded_in :family

  field :source, type: String
  field :application_id, type: BSON::ObjectId
  field :start_on, type: Date
  field :end_on, type: Date
  field :assistance_year, type: Integer
  field :determined_on, type: Date

  field :hbx_id, type: String

  validates_presence_of :start_on
  validates :source,
            allow_blank: false,
            inclusion: { in: SOURCE_KINDS,
                         message: "%{value} is not a valid source kind" }

  embeds_many :tax_households, cascade_callbacks: true

  before_save :generate_hbx_id

  index({ application_id:  1 })
  index({ start_on:  1 })
  index({ end_on:  1 })
  index({ assistance_year:  1 })
  index({ :"tax_households._id" => 1 })


  # Scopes
  scope :by_year,   ->(year) { where(assistance_year: year) }
  scope :active,    ->{ where(end_on: nil) }
  scope :inactive,  ->{ where(:end_on.ne => nil) }
  scope :current_and_prospective_by_year, ->(year) { where(:assistance_year.gte => year) }

  def latest_active_tax_household_with_year(year)
    tax_households.tax_household_with_year(year).active_tax_household.order_by(:created_at.desc).first
  end

  private

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_tax_household_group_id) if hbx_id.blank?
  end
end
