module SponsoredBenefits
  module Organizations
    class PlanDesignProposal
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM

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
      scope :initial, -> { all }
      scope :renewing, -> { none }
      scope :draft, -> { where(aasm_state: 'draft') }
      scope :published, -> { where(aasm_state: 'published') }
      scope :expired, -> { where(:'effective_date'.lt => TimeKeeper.date_of_record) }

      def self.find(id)
        organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where("plan_design_proposals._id" => BSON::ObjectId.from_string(id)).first
        organization.plan_design_proposals.detect{|proposal| proposal.id == BSON::ObjectId.from_string(id)}
      end

      def can_quote_be_published?
        self.valid?
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

        event :publish do
          transitions from: :draft, to: :published, :guard => "can_quote_be_published?", after: :set_employer_claim_code
        end

        event :claim do
          transitions from: :published, to: :claimed
        end
      end


    end
  end
end
