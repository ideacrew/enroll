# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::SeedsController, :type => :controller do
  include L10nHelper

  let(:user) { FactoryBot.create(:user, :hbx_staff, :with_hbx_staff_role) }
  let(:hbx_staff_role) { double("hbx_staff_role", permission: hbx_permission)}
  let(:hbx_profile) { double("HbxProfile")}
  let(:hbx_permission) { FactoryBot.create(:permission, :hbx_staff) }
  let(:person) { double("person", agent?: true)}
  before :each do
    allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
    allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
    sign_in(user)
  end

  let(:file_location) { csv_file_to_upload }
  let(:csv_file_to_upload) do
    filename = "#{Rails.root}/ivl_testbed_scenarios_*.csv"
    ivl_testbed_templates = Dir.glob(filename)
    ivl_testbed_templates.first
  end
  let(:update_params) do
    {
      id: latest_seed.id,
      commit: "begin seed"
    }
  end
  # Uses a CSV stored in enroll app in enroll with incompatible headers
  let(:random_csv_in_enroll) do
    "#{Rails.root}/spec/test_data/cancel_plan_years/CancelPlanYears.csv"

  end
  let(:create_params) do
    {
      file: fixture_file_upload(file_location, 'text/csv'),
      csv_template: 'individual_market_seed'
    }.with_indifferent_access
  end

  let(:non_csv_create_params) do
    {
      file: fixture_file_upload(file_location, 'pdf'),
      csv_template: 'individual_market_seed'
    }.with_indifferent_access
  end

  let(:wrong_row_csv_params) do
    {
      file: fixture_file_upload(random_csv_in_enroll, "text/csv"),
      csv_template: 'individual_market_seed'
    }.with_indifferent_access
  end

  let(:latest_seed) { Seeds::Seed.last || Seeds::Seed.new(filename: "Fake", user: user).save! }

  describe "#index" do
    it "should render without issues" do
      get :index, xhr: true
      expect(response).to have_http_status(:success)
    end
  end

  describe "#new" do
    it "should render a new form" do
      get :new, xhr: true
      expect(response).to have_http_status(:success)
      # expect(response).to render_template(
      #  "exchanges/seeds/new.html.erb",
      #  "layouts/bootstrap_4"
      # )
    end
  end

  describe "#create" do
    # TODO: need to figure out how to mock the file going through. Just isn't working at the test level.
    it "should successfully create a seed record from a CSV with all of the attributes from the CSV assigned to seed rows" do
      return unless file_location.present?
      # because it uploads a file from the UI, it will be a bit different format.
      # TODO: Look up the API for this and mock it here better
      post :create, params: create_params, as: :json
      # expect(response).to redirect_to(edit_exchanges_seed_path(latest_seed.id))
      expect(flash[:success]).to eq(l10n("seeds_ui.seed_created_message"))
      expect(Seeds::Seed.count).to be > 0
      expect(Seeds::Seed.first.rows.count).to be > 0
    end
    context "CSV format" do
      it "should show an error to user if type uploaded is not a CSV" do
        post :create, params: non_csv_create_params, as: :json
        expect(flash[:error]).to eq("Unable to use CSV template. Must be in CSV format.")
      end

      it "should show an error to user if CSV contains incorrect headers" do
        post :create, params: wrong_row_csv_params, as: :json
        expect(flash[:error]).to include("CSV does not match individual_market_seed template. Must use headers (in any order) ")
      end
    end
    it "does not allow docx files to be uploaded" do
      create_params[:file] = fixture_file_upload("#{Rails.root}/test/sample.docx")
      post :create, params: create_params, as: :json

      expect(flash[:error]).to include("Unable to use CSV template")
    end
  end
  describe "#edit" do
    it "should render the edit page when seed id is passed" do
      get :edit, params: {id: latest_seed.id}, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/seeds/edit", "layouts/bootstrap_4")
    end
  end

  describe "#update" do
    it "should begin to process the seed in the background" do
      return unless file_location.present?
      put :update, params: update_params
      # expect(response).to redirect_to(edit_exchanges_seed_path(latest_seed.id))
      expect(flash[:notice]).to eq(l10n("seeds_ui.begin_seed_message"))
    end
  end
end
