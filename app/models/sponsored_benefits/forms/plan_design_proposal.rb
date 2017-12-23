module SponsoredBenefits
  module Forms
    class PlanDesignProposal

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_reader :title, :effective_date, :zip_code, :county, :sic_code, :quote_date
      attr_reader :profile
      attr_reader :plan_design_organization
      attr_reader :proposal
      attr_reader :file

      validates_presence_of :title, :effective_date, :sic_code, :county, :zip_code

      def initialize(attrs = {})
        assign_wrapper_attributes(attrs)
        ensure_proposal
        ensure_profile
        ensure_sic_zip_county
      end

      def assign_wrapper_attributes(attrs = {})
        attrs.each_pair do |k,v|
          self.send("#{k}=", v)
        end
      end

      def organization=(val)
        @plan_design_organization = val
      end

      def profile=(attrs)
      end

      def title=(val)
        @title = val
      end

      def effective_date=(val)
        @effective_date = Date.strptime(val, "%m/%d/%Y")
      end

      def proposal_id=(val)
        return if val.blank?
        @proposal = @plan_design_organization.plan_design_proposals.detect{|proposal| proposal.id.to_s == val }
        if @proposal.present?
          @profile = @proposal.profile
          prepopulate_attributes
        end
      end

      def prepopulate_attributes
        @title = @proposal.title
        @effective_date = @profile.benefit_sponsorships.first.initial_enrollment_period.min.strftime("%m/%d/%Y")
        @quote_date = @proposal.updated_at.strftime("%m/%d/%Y")
      end

      def ensure_proposal
        @proposal = @plan_design_organization.plan_design_proposals.build unless @proposal.present?
      end

      def ensure_sic_zip_county
        @sic_code = @plan_design_organization.sic_code
        location = @plan_design_organization.office_locations.first
        @zip_code = location.address.zip
        @county = location.address.county
      end

      def ensure_profile
        if @profile.blank?
          @profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new
          sponsorship = @profile.benefit_sponsorships.build
          sponsorship.benefit_applications.build
        end
      end

      def save
        initial_enrollment_period = @effective_date..(@effective_date.next_year.prev_day)

        if @proposal.persisted?
          @proposal.assign_attributes(title: @title)
          @proposal.profile.benefit_sponsorships.first.assign_attributes(initial_enrollment_period: initial_enrollment_period, annual_enrollment_period_begin_month: @effective_date.month)
        else
          profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({sic_code: @sic_code})
          @proposal = @plan_design_organization.plan_design_proposals.build({title: @title, profile: profile})
          sponsorship = @proposal.profile.benefit_sponsorships.build({benefit_market: :aca_shop_cca, initial_enrollment_period: initial_enrollment_period, annual_enrollment_period_begin_month: @effective_date.month})
        end

        @plan_design_organization.save
      end

      # def census_dependents=(attrs)
      # end

      # def save
      #   census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployeeBuilder.build do |builder|
      #     builder.add_first_name(first_name)
      #     builder.add_last_name(last_name)
      #     builder.add_ssn(ssn)
      #     builder.add_dob(dob)
      #     builder.add_dependent(dependent)
      #   end

      #   census_employee.save
      # end
    end
  end
end
