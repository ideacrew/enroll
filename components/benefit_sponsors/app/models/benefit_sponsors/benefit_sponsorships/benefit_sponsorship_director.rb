module BenefitSponsors
  class BenefitSponsorships::BenefitSponsorshipDirector

    attr_reader :new_date

    def initialize(new_date = TimeKeeper.date_of_record)
      @new_date = new_date
      initialize_logger
    end

    def process(benefit_sponsorships, event)
      business_policy_name = policy_name(event)

      benefit_sponsorships.no_timeout.each do |benefit_sponsorship|
        begin
          business_policy = business_policy_for(benefit_sponsorship, business_policy_name)
          sponsor_service_for(benefit_sponsorship).execute(benefit_sponsorship, event, business_policy)
        rescue Exception => e
          @logger.info "EXCEPTION: Event (#{event}) failed for Employer #{benefit_sponsorship.legal_name}(#{benefit_sponsorship.fein})"
          @logger.error e.message
          @logger.error e.backtrace.join("\n")
        end
      end
    end

    def business_policy_for(benefit_sponsorship, business_policy_name)
      sponsor_policy.business_policies_for(benefit_sponsorship, business_policy_name)
    end

    def sponsor_service_for(benefit_sponsorship)
      if benefit_sponsorship.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
        sponsorship_service
      end
    end

    def policy_name(event_name)
      event_name
    end

    private

    def sponsorship_service
      return @sponsorship_service if defined? @sponsorship_service
      @sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(new_date: new_date)
    end

    def sponsor_policy
      return @sponsor_policy if defined?(@sponsor_policy)
      @sponsor_policy = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipPolicy.new
    end

    def initialize_logger
      @logger = Logger.new("#{Rails.root}/log/benefit_sponsorship_director.log") unless defined? @logger
    end
  end
end