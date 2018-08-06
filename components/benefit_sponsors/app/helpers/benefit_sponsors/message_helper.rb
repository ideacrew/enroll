module BenefitSponsors
  module MessageHelper

    def unread_messages(profile)
      BenefitSponsors::Services::MessageService.unread_messages(message_recipient(profile))
    end

    private

    def message_recipient(profile)
      if profile.is_a? BenefitSponsors::Organizations::Profile
        profile
      else
        BenefitSponsors::Organizations::Profile.find profile.id
      end
    end
  end
end
