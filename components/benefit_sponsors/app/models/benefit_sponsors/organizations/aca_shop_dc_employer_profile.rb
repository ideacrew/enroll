module BenefitSponsors
  module Organizations
    class AcaShopDcEmployerProfile < BenefitSponsors::Organizations::Profile
      # include BenefitSponsors::Employers::EmployerHelper
      include BenefitSponsors::Concerns::EmployerProfileConcern
      include BenefitSponsors::Concerns::Observable

      add_observer BenefitSponsors::Observers::EmployerProfileObserver.new, [:update]
      add_observer BenefitSponsors::Observers::NoticeObserver.new, [:process_employer_profile_events]

      after_update :notify_observers

      def rating_area
        # FIX this
      end

      def sic_code
        # FIX THIS
      end

      # def census_employees
      #   CensusEmployee.find_by_employer_profile(self)
      # end

      private

      def site
        return @site if defined? @site
        @site = BenefitSponsors::Site.by_site_key(EnrollRegistry[:enroll_app].setting(:site_key).item).first
      end

      def initialize_profile
        if is_benefit_sponsorship_eligible.blank?
          write_attribute(:is_benefit_sponsorship_eligible, true)
          @is_benefit_sponsorship_eligible = true
        end

        self
      end

      def build_nested_models
        return if inbox.present?
        build_inbox
        welcome_subject = "Welcome to #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
        welcome_body = "#{EnrollRegistry[:enroll_app].setting(:short_name).item} is the #{Settings.aca.state_name}'s online marketplace where benefit sponsors may select and offer products that meet their member's needs and budget."
        unless inbox.messages.where(body: welcome_body).present?
          inbox.messages.new(subject: welcome_subject, body: welcome_body, from: EnrollRegistry[:enroll_app].setting(:short_name).item, created_at: Time.now.utc)
        end
      end
    end
  end
end
