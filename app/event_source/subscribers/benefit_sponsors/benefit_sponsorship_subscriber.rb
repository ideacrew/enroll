# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to benefit sponsorship
    class BenefitSponsorshipSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.benefit_sponsorship']

      subscribe(:on_osse_renewal) do |delivery_info, _metadata, response|
        payload = JSON.parse(response, :symbolize_names => true)
        benefit_sponsorship = GlobalID::Locator.locate(payload[:gid])
        eligibility_date = payload[:eligibility_date].to_date
        effective_date = payload[:effective_date].to_date

        eligibility = benefit_sponsorship.eligibility_for("aca_shop_osse_eligibility_#{eligibility_date.year}".to_sym, eligibility_date)
        osse_eligibility = eligibility.blank? ? false : eligibility.is_eligible_on?(eligibility_date)

        result = ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
          {
            subject: benefit_sponsorship.to_global_id,
            evidence_key: :shop_osse_evidence,
            evidence_value: osse_eligibility.to_s,
            effective_date: effective_date
          }
        )

        if result.success?
          subscriber_logger.info "OSSE renewed; FEIN - #{benefit_sponsorship.fein}"
        else
          subscriber_logger.info "OSSE renewal failed; FEIN - #{benefit_sponsorship.fein}; Error: #{result.failure}"
        end

        subscriber_logger.info "on_benefit_sponsorship_osse_renewal, FEIN - #{benefit_sponsorship.fein}"
        subscriber_logger.info "BenefitSponsorshipSubscriber on_benefit_sponsorship_osse_renewal payload: #{payload}"

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "BenefitSponsorshipSubscriber, FEIN - #{benefit_sponsorship.fein}, error message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_benefit_sponsorship_osse_renewal_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
