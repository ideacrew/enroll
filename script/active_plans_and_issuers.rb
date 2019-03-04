class ActivePlans #Exporter
  attr_reader :lines

  def retrieve(compare_date = TimeKeeper.date_of_record)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {
      :$elemMatch => {:"effective_period.max".gt => compare_date, :aasm_state => :active }
    }).each do |benefit_sponsorship|
      benefit_sponsorship.benefit_applications.each do |benefit_application|
        @lines += BenefitSponsors::Serializers::BenefitApplicationIssuer.to_csv(benefit_application)
      end
    end
  end

  def write
    File.open('active_plans_and_issuers.csv', 'w') do |csv|
      csv.puts "employer_hbx_id,employer_fein,effective_period_start_on,effective_period_end_on,carrier_hbx_id},carrier_fein"
      @lines.each { |line| csv.puts line }
    end
  end

  def initialize(file_name="active_plans_and_issuers.csv")
    @file_name = file_name
    @lines = []
    self.retrieve
  end
end

ActivePlans.new.write
