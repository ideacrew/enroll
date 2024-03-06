# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe EventLogs::MonitoredEvent, type: :model, dbclean: :around_each do
  describe "person monitored event" do
    before(:each) do
      @user = FactoryBot.create(:user)
      @person_event_log =
        FactoryBot.create(:people_eligibilities_event_log, account: @user)
      @monitored_event =
        FactoryBot.create(
          :monitored_event,
          account_username: @user.email,
          monitorable: @person_event_log
        )
      @monitored_event_2 =
        FactoryBot.create(
          :monitored_event,
          event_category: :osse,
          subject_hbx_id: "10005",
          monitorable: @person_event_log
        )
    end

    context ".save" do
      it "should persist event log" do
        expect(EventLogs::MonitoredEvent.count).to eq 2
        expect(EventLogs::MonitoredEvent.first).to eq @monitored_event
      end

      it "should find events from collection" do
        expect(
          EventLogs::MonitoredEvent.where(
            @monitored_event.attributes.slice(:account_hbx_id, :event_category)
          ).first
        ).to eq @monitored_event
      end
    end

    context ".get_category_options" do
      it "should return event category options" do
        expect(EventLogs::MonitoredEvent.get_category_options).to eq %i[
             login
             osse
           ]
      end

      it "should return event category options for given subject" do
        expect(
          EventLogs::MonitoredEvent.get_category_options(
            @monitored_event.subject_hbx_id
          )
        ).to eq [:login]
      end
    end

    context ".fetch_event_logs" do
      let(:params) { { account: @user.email, event_category: :login } }
      it "should return event logs" do
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given subject" do
        params[:subject_hbx_id] = @monitored_event.subject_hbx_id
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given account" do
        params[:account] = @monitored_event.account_hbx_id
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given account username" do
        params[:account] = @monitored_event.account_username
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).size).to eq(1)
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given event start date" do
        params[:event_start_date] = @monitored_event.event_time.to_date
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).size).to eq(1)
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given event end date" do
        params[:event_end_date] = @monitored_event.event_time.to_date
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given event start and end date" do
        params[:event_start_date] = @monitored_event.event_time.to_date
        params[:event_end_date] = @monitored_event.event_time.to_date
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return event logs for given account and event start date" do
        params[:account] = @monitored_event.account_hbx_id
        params[:event_start_date] = @monitored_event.event_time.to_date
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).size).to eq(1)
        expect(
          EventLogs::MonitoredEvent.fetch_event_logs(params).first
        ).to eq @monitored_event
      end

      it "should return all event logs if no params are passed" do
        expect(EventLogs::MonitoredEvent.fetch_event_logs({}).count).to eq(2)
      end
    end
  end

  describe "organization monitored event" do
    include_context "setup benefit market with market catalogs and product packages"

    let(:site) do
      ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
    end
    let(:benefit_market) { site.benefit_markets.first }

    let(:employer_organization) do
      FactoryBot.create(
        :benefit_sponsors_organizations_general_organization,
        :with_aca_shop_dc_employer_profile,
        site: site
      )
    end

    let(:benefit_sponsorship) do
      employer_organization.active_benefit_sponsorship
    end
    let(:current_year) { TimeKeeper.date_of_record.year }
    let(:current_effective_date) { Date.new(Date.today.year, 3, 1) }

    let!(:catalog_eligibility) do
      ::Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: current_benefit_market_catalog.to_global_id,
          eligibility_feature: "aca_shop_osse_eligibility",
          effective_date:
            current_benefit_market_catalog.application_period.begin.to_date,
          domain_model:
            "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end

    let!(:shop_osse_eligibility) do
      osse_eligibility =
        ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
          {
            subject: benefit_sponsorship.to_global_id,
            evidence_key: :shop_osse_evidence,
            evidence_value: "true",
            effective_date: beginning_of_year
          }
        )
      osse_eligibility
    end

    let!(:system_user) { FactoryBot.create(:user, email: "admin@dc.gov") }
    let(:beginning_of_year) { TimeKeeper.date_of_record.beginning_of_year }

    include_context "setup initial benefit application" do
      let(:current_effective_date) do
        Date.new(TimeKeeper.date_of_record.year, 2, 1)
      end
    end

    before do
      allow(::EnrollRegistry).to receive(:feature?).and_return(true)
      allow(::EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      TimeKeeper.set_date_of_record_unprotected!(beginning_of_year + 4.months)
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context ".eligibility_details" do
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
      let!(:system_user) do
        FactoryBot.create(:user, person: person, email: "admin@dc.gov")
      end
      let(:subject_gid) do
        benefit_sponsorship.organization.to_global_id.uri.to_s
      end

      let(:current_state) { :eligible }

      let(:payload) do
        {
          current_state: current_state,
          title: "Aca Shop Osse Eligibility 2024",
          state_histories: [{ effective_on: Date.new(2024, 1, 1) }]
        }
      end

      let(:session_details) do
        {
          session_id: SecureRandom.uuid,
          login_session_id: SecureRandom.uuid,
          portal: "http://dchealthlink.com"
        }
      end

      let(:headers) do
        {
          correlation_id: SecureRandom.uuid,
          message_id: SecureRandom.uuid,
          host_id: "https://demo.dceligibility.assit.org",
          subject_gid: subject_gid,
          resource_gid: subject_gid,
          event_time: DateTime.now,
          event_name: event_name,
          account: {
            id: system_user.id.to_s,
            session: session_details
          }
        }
      end

      let(:event_name) do
        "events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_created"
      end

      let(:monitored_event) { event_log.monitored_event }

      let(:event_log) do
        Operations::EventLogs::Store
          .new
          .call(payload: payload, headers: headers)
          .success
      end

      let(:eligibility_effective_date) do
        payload.dig(:state_histories, -1, :effective_on)
      end

      context "when application osse eligible" do
        before do
          allow_any_instance_of(
            BenefitSponsors::BenefitApplications::BenefitApplication
          ).to receive(:osse_eligible?).and_return(true)
        end

        subject { monitored_event.eligibility_details }

        it "should return osse eligibile application effective date" do
          expect(
            subject[:effective_on]
          ).to eq initial_application.effective_period.min
        end

        it "should return other attributes" do
          expect(subject[:current_state]).to eq payload[:current_state].to_s
          expect(
            subject[:subject]
          ).to eq benefit_sponsorship.organization.legal_name
          expect(subject[:title]).to eq "SHOP HC4CC 2024"
          expect(subject[:detail]).to eq "Eligibility Created"
          expect(subject[:event_time].to_date).to eq event_log
            .event_time
            .in_time_zone("Eastern Time (US & Canada)")
            .to_date
        end

        context "when eligibility is in ineligible state" do
          let(:current_state) { :ineligible }

          it "should return eligibility effective date" do
            expect(
              subject[:effective_on]
            ).to eq eligibility_effective_date
          end

          it "should return other attributes" do
            expect(subject[:current_state]).to eq current_state.to_s
            expect(
              subject[:subject]
            ).to eq benefit_sponsorship.organization.legal_name
            expect(subject[:title]).to eq "SHOP HC4CC 2024"
            expect(subject[:detail]).to eq "Eligibility Created"
            expect(subject[:event_time].to_date).to eq event_log
              .event_time
              .in_time_zone("Eastern Time (US & Canada)")
              .to_date
          end
        end
      end

      context "when application not osse eligible" do
        before do
          allow_any_instance_of(
            BenefitSponsors::BenefitApplications::BenefitApplication
          ).to receive(:osse_eligible?).and_return(false)
        end

        subject { monitored_event.eligibility_details }

        it "should return eligibility effective date" do
          expect(subject[:effective_on]).to eq eligibility_effective_date
        end

        it "should return other attributes" do
          expect(subject[:current_state]).to eq payload[:current_state].to_s
          expect(
            subject[:subject]
          ).to eq benefit_sponsorship.organization.legal_name
          expect(subject[:title]).to eq "SHOP HC4CC 2024"
          expect(subject[:detail]).to eq "Eligibility Created"
          expect(subject[:event_time].to_date).to eq event_log
            .event_time
            .in_time_zone("Eastern Time (US & Canada)")
            .to_date
        end
      end
    end
  end
end
