  module Forms
    class AdminPlanYearForm
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :start_on, String
      attribute :end_on, String
      attribute :open_enrollment_start_on, String
      attribute :open_enrollment_end_on, String
      attribute :fte_count, Integer, default: 0
      attribute :admin_dt_action, Boolean, default: true

      attribute :start_on_options, Hash
      attribute :organization_id, String

      validate :validate_oe_dates
      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true
      validates_presence_of :fte_count

      def self.for_new(params)
        form = self.new(params)
        form.set_start_on_dates
        form
      end

      def get_end_on(date)
        (date.next_year - 1.day).to_s
      end

      def set_start_on_dates
        start_on_dates = PlanYear.calculate_start_on_options(admin_dt_action).inject([]) do |dates, date_arr|
          dates << date_arr.second.to_date
        end

        start_on_dates.each do |date|
          oe_dates_hash = PlanYear.calculate_open_enrollment_date(date, admin_dt_action)
          oe_dates_hash.keys.each { |key| oe_dates_hash[key] = oe_dates_hash[key].to_s }
          self.start_on_options[date] = {
            :start_on => date.to_s, :end_on => get_end_on(date)
          }
          self.start_on_options[date].merge!(oe_dates_hash)
        end
      end

      def self.for_create(params)
        form = self.new(params)
        form.organization_id = params["employer_actions_id"].split('_').last
        form
      end

      def save
        return false unless self.valid?
        create_plan_year
      end

      def can_create_plan_year?(employer_profile)
        employer_profile.plan_years.active_states_per_dt.present? ? false : true
      end

      def get_date(date)
        Date.strptime(date, '%m/%d/%Y')
      end

      def cancel_draft_applications(new_plan_year)
        new_plan_year.employer_profile.plan_years.draft.select{|py| py != new_plan_year}.each do |pl_year|
          pl_year.cancel! if pl_year.may_cancel?
        end
      end

      def create_plan_year
        employer_profile = Organization.find(organization_id).employer_profile
        if employer_profile && can_create_plan_year?(employer_profile)
          new_plan_year = employer_profile.plan_years.create({start_on: get_date(start_on), end_on: get_date(end_on), open_enrollment_start_on: get_date(open_enrollment_start_on), open_enrollment_end_on: get_date(open_enrollment_end_on), fte_count: fte_count})
          employer_profile.save!
          cancel_draft_applications(new_plan_year)
        else
          errors.add(:base, "Existing plan year with overlapping coverage exists")
          return false
        end
      end

      def validate_oe_dates
        if open_enrollment_end_on <= open_enrollment_start_on
          errors.add(:base, "Open Enrollment Start Date can't be later than the Open Enrollment End Date")
        end
      end
    end
  end
