class QhpRateBuilder
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_plan_rates_#{Time.now.to_s.gsub(' ', '')}.log"
  LOGGER = Logger.new(LOG_PATH)
  INVALID_PLAN_IDS = ["78079DC0320003","78079DC0320004","78079DC0340002","78079DC0330002"]

  def initialize
    @rates_array = []
  end

  def add(rates_hash)
    @rates_array = @rates_array + rates_hash[:items]
  end

  def run
    @results = Hash.new{|results,k| results[k] = []}
    @rates_array.each do |rate|
      @rate = rate
      build_premium_tables
    end
    find_plan_and_create_premium_tables
  end

  def build_premium_tables
    @results[@rate[:plan_id]] << {
      age: assign_age,
      start_on: @rate[:effective_date],
      end_on: @rate[:expiration_date],
      cost: @rate[:primary_enrollee]
    }
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
    @results.each do |plan_id, premium_tables|
      unless INVALID_PLAN_IDS.include?(plan_id)
        @plan = Plan.where(hios_id: /#{plan_id}/, active_year: @rate[:effective_date].to_date.year)
        @plan.each do |plan|
          plan.premium_tables.create!(premium_tables)
        end
      end
    end
  end
end
