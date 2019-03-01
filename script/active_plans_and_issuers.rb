class ActivePlans #Exporter
  def self.retrieve(compare_date = TimeKeeper.date_of_record)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {
      :$elemMatch => {:"effective_period.max".lt => compare_date, :aasm_state => :active }
    }).each do |bs|
      puts bs.inspect
    end.to_a
  end

  def write
    File.open(@file_name, 'w') do |csv|
      csv.puts "employer_hbx_id,employer_fein,effective_period_start_on,effective_period_end_on,carrier_hbx_id},carrier_fein"
      @lines.each { |line| csv.puts line }
    end
  end

  def self.initialize(file_name="active_plans_and_issuers.csv")
    @file_name = file_name
    @lines = []
  end
end
