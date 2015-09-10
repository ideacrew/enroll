class QhpRateBuilder
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_plan_rates_#{Time.now.to_s.gsub(' ', '')}.log"
  LOGGER = Logger.new(LOG_PATH)
  INVALID_PLAN_IDS = ["78079DC0320003","78079DC0320004","78079DC0340002","78079DC0330002"]

  def initialize(rates_hash)
    @rates_array = []
    @rates_hash = rates_hash
  end

  def add(rates_hash)
    @rates_array = @rates_array + rates_hash[:items]
  end

  def run
    @rates_array.each do |rate|
      @rate = rate
      assign_price_attributes
      find_plan_and_create_premium_tables
    end
  end

  def assign_price_attributes
    @age = assign_age
    @start_on = @rate[:effective_date]
    @end_on = @rate[:expiration_date]
    @cost = @rate[:primary_enrollee]
    @hios_id = @rate[:plan_id]
  end

  def assign_age
    case(@rate[:age_number])
    when "0-20"
      20
    when "65 and over"
      65
    else
      @rate[:age_number].to_i
    end
  end

  def find_plan_and_create_premium_tables
    unless INVALID_PLAN_IDS.include?(@hios_id)
      plan = Plan.find_by(hios_id: /#{@hios_id}/, active_year: 2016)
      create_premium_tables(plan)
    end
  end

  def create_premium_tables(plan)
    pt = plan.premium_tables.build(
      age: @age,
      start_on: @start_on,
      end_on: @end_on,
      cost: @cost
      )
    pt.save!
  end

end
