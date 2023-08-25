# frozen_string_literal: true

module Events
  module BenefitSponsors
    # This class will register event
    class OsseRenewal < EventSource::Event
      publisher_path 'publishers.benefit_sponsors.benefit_sponsorship_publisher'
    end
  end
end
