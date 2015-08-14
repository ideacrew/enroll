class BenefitCoveragePeriod
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_sponsorship

  field :title, type: String

  # Market where benefits are available
  field :service_market, type: String

  # Eligibility time period
  field :start_on, type: Date
  field :end_on, type: Date
  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  # Second Lowest Cost Silver Plan, by rating area (only one rating area in DC)
  field :slcsp, type: BSON::ObjectId

  # embeds_many :open_enrollment_periods, class_name: "EnrollmentPeriod"
  embeds_many :benefit_packages

  accepts_nested_attributes_for :benefit_packages

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, message: "is invalid"

  validates :service_market,
    inclusion: { in: BenefitSponsorship::SERVICE_MARKET_KINDS, message: "%{value} is not a valid service market" }

  validate :end_date_follows_start_date

  before_save :set_title

  # The universe of products this sponsor may offer during this time period
  def benefit_products
  end

  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  def open_enrollment_contains?(date)
    (open_enrollment_start_on <= date) && (date <= open_enrollment_end_on)
  end

  def earliest_effective_date
    if TimeKeeper.date_of_record.day < 16
      TimeKeeper.date_of_record.end_of_month + 1.day
    else
      TimeKeeper.date_of_record.next_month.end_of_month + 1.day
    end
  end

  ## Class methods
  class << self

    def find(id)
      organizations = Organization.where("hbx_profile.benefit_sponsorship.benefit_coverage_periods._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods.first : nil
    end

  end

private
  def end_date_follows_start_date
    return unless self.end_on.present?
    # Passes validation if end_on == start_date
    errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
  end

  def set_title
    return if title.present?
    service_market == "shop" ? market_name = "SHOP" : market_name = "Individual"
    self.title = "#{market_name} Market Benefits #{start_on.year}"
  end

end
