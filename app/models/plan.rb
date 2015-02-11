class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :carrier                                                                                                                    

  auto_increment :hbx_id, :seed => 999

  field :year, type: Integer
  field :hios_plan_id, type: String

  field :start_on, type: Date
  field :end_on, type: Date

  field :name, type: String
  field :abbreviation, type: String
  field :coverage_type, type: String
  field :market_type, type: String
  field :metal_level, type: String
  field :ehb_pct_as_int, type: Integer, default: 0

  validates_inclusion_of :coverage_type, in: ["health", "dental"]
  validates_inclusion_of :market_type, in: ["individual", "shop"]

  belongs_to :renewal_plan, :class_name => "Plan"
  has_many :policies, :inverse_of => :plan
  has_and_belongs_to_many :employers

  embeds_many :premium_tables

  before_save :invalidate_find_cache

  scope :by_name, ->{order_by(name: 1, hios_plan_id: 1)}

  def invalidate_find_cache
#    Rails.cache.delete("Plan/find/hios_plan_id.#{self.hios_plan_id}")
    Rails.cache.delete("Plan/find/hios_plan_id.#{self.hios_plan_id}.#{self.year}")
    true
  end

  def self.find_by_hios_id_and_year(h_id, year)
#    Rails.cache.fetch("Plan/find/hios_plan_id.#{h_id}.#{year}") do
      Plan.where(
        :hios_plan_id => h_id,
        :year => year
      ).first
#    end
  end

#  def self.find_by_hios_id(h_id)
#    Rails.cache.fetch("Plan/find/hios_plan_id.#{h_id}") do
#      Plan.where(
#        :hios_plan_id => h_id
#      ).first
#    end
#  end

  # Provide premium rate given the rate schedule, date coverage will start, and applicant age when coverage starts
  def rate(rate_period_date, benefit_begin_date, birth_date)
    age = Ager.new(birth_date).age_as_of(benefit_begin_date)
    premiums = Collections::Premiums.new(self.premium_tables).for_date(rate_period_date).for_age(age)
    premiums.to_a.first
  end

  def premium_for_enrollee(enrollee)
    rate(enrollee.rate_period_date, enrollee.benefit_begin_date, enrollee.birth_date)
  end

  def self.default_search_order
    [
      ["name", 1]
    ]
  end

  def self.search_hash(s_str)
    search_rex = Regexp.compile(Regexp.escape(s_str), true)
    {
      "$or" => [
        {"name" => search_rex}
      ]
    }
  end

  HIOS_2015_MAP = {
    "77422DC0060001" => "77422DC0060002",
    "77422DC0060003" => "77422DC0060002",
#    "77422DC0060004" => "77422DC0060004",
#    "77422DC0060005" => "77422DC0060005",
#    "77422DC0060006" => "77422DC0060006",
    "77422DC0060007" => "77422DC0060008",
    "77422DC0060009" => "77422DC0060008",
    "78079DC0210001" => "78079DC0210001" }
#    "77422DC0060002" => "77422DC0060002",
#    "77422DC0060008" => "77422DC0060008",
#    "78079DC0160001" => "78079DC0160001",
#    "78079DC0180001" => "78079DC0180001",
#    "78079DC0200001" => "78079DC0200001",
#    "86052DC0400001" => "86052DC0400001",
#    "86052DC0400002" => "86052DC0400002",
#    "86052DC0400003" => "86052DC0400003",
#    "86052DC0400004" => "86052DC0400004",
#    "86052DC0410001" => "86052DC0410001",
#    "86052DC0410002" => "86052DC0410002",
#    "86052DC0410003" => "86052DC0410003",
#    "86052DC0420001" => "86052DC0420001",
#    "86052DC0420002" => "86052DC0420002",
#    "86052DC0430001" => "86052DC0430001",
#    "86052DC0430002" => "86052DC0430002",
#    "94506DC0390001" => "94506DC0390001",
#    "94506DC0390002" => "94506DC0390002",
#    "94506DC0390003" => "94506DC0390003",
#    "94506DC0390004" => "94506DC0390004",
#    "94506DC0390005" => "94506DC0390005",
#    "94506DC0390006" => "94506DC0390006",
#    "94506DC0390007" => "94506DC0390007",
#    "94506DC0390008" => "94506DC0390008",
#    "94506DC0390009" => "94506DC0390009",
#    "94506DC0390010" => "94506DC0390010"
#  }

  def plan_for_2015
    split = hios_plan_id.split("-")
    without_variant = split.first
    variant = split.last

    found = HIOS_2015_MAP[without_variant]
    return self if(found.nil?)

    Plan.find_by_hios_id("#{found}-#{variant}")
  end
end
