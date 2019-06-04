module BenefitSponsors
  module Organizations
    class AcaShopCcaEmployerProfile < BenefitSponsors::Organizations::Profile
      # include Concerns::AcaRatingAreaConfigConcern
      # include BenefitSponsors::Concerns::EmployerProfileConcern
      # include BenefitSponsors::Concerns::Observable

      field :sic_code,            type: String
      field :referred_by,         type: String
      field :referred_reason,     type: String

      # TODO use SIC code validation
      validates_presence_of :sic_code

      embeds_one  :employer_attestation, class_name: '::EmployerAttestation'

      # add_observer BenefitSponsors::Observers::EmployerProfileObserver.new, [:update, :notifications_send]

      # after_update :notify_observers

      REFERRED_KINDS = ['Radio', 'Sign on bus, subway, gas station, etc.', 'Online advertisement, such as on Google or Pandora', 'Billboard', 'Video on a website', 'Social media, such as Facebook', 'Online search (for example, searching through Google for places to get insurance)', 'Insurance broker', 'Health insurance company/carrier', 'Hospital or community health center', 'Health insurance Assister or Navigator', 'State or Government Agency (Main Streets or Small Business Administration) ', 'Employer Association', 'Chamber of Commerce', 'Friend or family member', 'Health Connector sponsored event', 'New England Benefits Association (NEBA)', 'Greater Boston Chamber of Commerce', 'Television', 'Newspaper', 'Other']
    end
  end
end
