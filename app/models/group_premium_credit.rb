# frozen_string_literal: true

# A model for grouping members with their premium credits.
# Each Group Premium Credit has one or more {MemberPremiumCredit}.
# Each Group Premium Credit can be mapped to a authority_determination. Also, can be mapped to a sub_group.

# For Individual context:
#   A set of applicants, grouped according to IRS and ACA rules,
#   who are considered a single unit when determining eligibility for Insurance Assistance and Medicaid.
  # Example: authority_determination can be FinancialAssistance::Application and
  #          sub_group can be FinancialAssistance::EligibilityDetermination
class GroupPremiumCredit
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %w[aptc_csr].freeze

  # Fields
  field :kind, type: String

  # AuthorityDetermination Information.
  # For IVL context,
  #   authority_determination_class can be FinancialAssistance::Application and
  #   authority_determination_id can be the BSON::ObjectId of FinancialAssistance::Application
  # For SHOP context,
  #   authority_determination_class can be BenefitSponsors::BenefitApplications::BenefitApplication and
  #   authority_determination_id can be the BSON::ObjectId of BenefitSponsors::BenefitApplications::BenefitApplication
  field :authority_determination_id, type: BSON::ObjectId
  field :authority_determination_class, type: String

  # Maximum Monthly Premium Credit
  # For IVL, premium_credit_monthly_cap is the monthly max_aptc for the entire group.
  # For SHOP/FEHB, premium_credit_monthly_cap is the monthly employer_contribution for the entire group.
  field :premium_credit_monthly_cap, type: Float

  # SubGroup Information.
  # For IVL context,
  #   sub_group_class can be FinancialAssistance::EligibilityDetermination and
  #   sub_group_id can be the BSON::ObjectId of FinancialAssistance::EligibilityDetermination
  # For SHOP context,
  #   sub_group_class can be BenefitSponsors::BenefitPackages::BenefitPackage and
  #   sub_group_id can be the BSON::ObjectId of BenefitSponsors::BenefitPackages::BenefitPackage
  field :sub_group_id, type: BSON::ObjectId
  field :sub_group_class, type: String

  field :expected_contribution_percentage, type: Float

  # Effective Period of GroupPremiumCredit.
  field :start_on, type: Date
  field :end_on, type: Date

  field :hbx_id, type: String
  field :family_id, type: BSON::ObjectId

  # Associations
  embeds_many :member_premium_credits, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :member_premium_credits

  # Scopes
  scope :by_year, ->(year) { where(start_on: (Date.new(year)..Date.new(year).end_of_year)) }
  scope :active, ->{ where(end_on: nil) }
  scope :aptc_csr, ->{ where(kind: 'aptc_csr') }

  # Validations
  validates_presence_of :start_on

  validates :kind,
            inclusion: { in: KINDS, message: "%{value} is not a valid group premium credit kind" },
            allow_blank: false

  validate :validate_dates

  before_save :generate_hbx_id

  def authority_determination
    return nil if authority_determination_id.blank? || authority_determination_class.blank?

    fetch_class_name(authority_determination_class).where(id: authority_determination_id).first
  rescue NameError, BSON::ObjectId::Invalid => e
    Rails.logger.error "GroupPremiumCredit Unable to find authority_determination error: #{e}, backtrace: #{e.backtrace.join('\n')}"
    nil
  end

  def sub_group
    return nil if sub_group_id.blank? || sub_group_class.blank?

    fetch_class_name(sub_group_class).find(sub_group_id)
  rescue NameError, BSON::ObjectId::Invalid => e
    Rails.logger.error "GroupPremiumCredit Unable to find sub_group error: #{e}, backtrace: #{e.backtrace.join('\n')}"
    nil
  end

  def family
    Family.find(family_id)
  end

  private

  def fetch_class_name(class_name)
    case class_name
    when '::FinancialAssistance::Application', 'FinancialAssistance::Application'
      FinancialAssistance::Application
    when '::FinancialAssistance::EligibilityDetermination', 'FinancialAssistance::EligibilityDetermination'
      FinancialAssistance::EligibilityDetermination
    else
      raise NameError
    end
  end

  def validate_dates
    return unless end_on.present? && start_on > end_on

    errors.add(:base, "end_on: #{end_on} cannot occur before start_on: #{start_on}")
  end

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_group_premium_credit_id) if hbx_id.blank?
  end
end
