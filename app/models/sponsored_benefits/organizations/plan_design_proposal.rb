module SponsoredBenefits
  module Organizations
    class PlanDesignProposal
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM

      RENEWAL_STATES = %w(renewing_draft renewing_published renewing_claimed renewing_expired)
      EXPIRABLE_STATES = %w(draft renewing_draft)

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      field :title, type: String
      field :submitted_date, type: Date

      field :claim_code, type: String
      field :claim_date, type: Date
      field :published_on, type: Date
      field :aasm_state, type: String

      embeds_one :profile, class_name: "SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile"
      delegate :effective_date, to: :profile
      validates_uniqueness_of :claim_code, :case_sensitive => false, :allow_nil => true

      scope :datatable_search, ->(query) { self.where({"$or" => ([{"title" => Regexp.compile(Regexp.escape(query), true)}])}) }
      ## TODO: how are we defining 'initial' vs 'renewing'?
      scope :initial, -> { not_in(aasm_state: RENEWAL_STATES) }
      scope :renewing, ->{ any_in(aasm_state: RENEWAL_STATES) }
      scope :draft, -> { any_in(aasm_state: %w(draft renewing_draft)) }
      scope :published, -> { any_in(aasm_state: %w(published renewing_published)) }
      scope :expired, -> { any_in(aasm_state: %w(expired renewing_expired)) }

      def self.find(id)
        organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where("plan_design_proposals._id" => BSON::ObjectId.from_string(id)).first
        organization.plan_design_proposals.detect{|proposal| proposal.id == BSON::ObjectId.from_string(id)}
      end

      def self.claim_code_status?(quote_claim_code)
        cc = self.where("claim_code" => quote_claim_code).first
        if cc.nil?
          return "invalid"
        else
          return cc.aasm_state
        end
      end

      def self.build_plan_year_from_quote(employer_profile_id, quote_claim_code)
        employer_profile = EmployerProfile.find(employer_profile_id)
        organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where(
          "plan_design_proposals.claim_code" => quote_claim_code,
          "plan_design_proposals.aasm_state" => "published"
        ).first

        quote = organization.plan_design_proposals.detect{ |pdp| pdp.claim_code == quote_claim_code }

        if quote.present? && quote_claim_code.present? && quote.published?
          plan_year = employer_profile.plan_years.build({
            start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month, end_on: ((TimeKeeper.date_of_record + 2.months).beginning_of_month + 1.year) - 1.day,
            open_enrollment_start_on: TimeKeeper.date_of_record, open_enrollment_end_on: (TimeKeeper.date_of_record + 1.month).beginning_of_month + 9.days,
            fte_count: quote.member_count
          })
        end

      end

      def can_quote_be_published?
        self.valid?
      end

      def can_be_expired?
        self.valid? && !plan_design_organization.is_prospect?
      end

      def generate_character
        ascii = rand(36) + 48
        ascii += 39 if ascii >= 58
        ascii.chr.upcase
      end

      def employer_claim_code
         4.times.map{generate_character}.join + '-' + 4.times.map{generate_character}.join
      end

      def set_employer_claim_code
        self.claim_code = employer_claim_code
        self.published_on = TimeKeeper.date_of_record
        self.save!
      end

      aasm do
        state :draft, initial: true
        state :published
        state :claimed
        state :expired
        state :renewing_draft
        state :renewing_published
        state :renewing_claimed
        state :renewing_expired

        event :publish do
          transitions from: :draft, to: :published, :guard => "can_quote_be_published?", after: :set_employer_claim_code
        end

        event :claim do
          transitions from: :published, to: :claimed
        end

        event :expire do
          transitions from: :draft, to: :expired, :guard => :can_be_expired?
          transitions from: :renewing_draft, to: :renewing_expired, :guard => :can_be_expired?
        end
      end


    end
  end
end
