# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::SeedsController, :type => :controller, dbclean: :after_each do
  let(:user) { FactoryBot.create(:user, :hbx_staff, :with_hbx_staff_role) }
  let(:hbx_staff_role) { double("hbx_staff_role", permission: hbx_permission)}
  let(:hbx_profile) { double("HbxProfile")}
  let(:hbx_permission) { FactoryBot.create(:permission, :hbx_staff) }
  let(:person) { double("person", agent?: true)}

  render_views

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
  let(:latest_seed) { Seeds::Seed.last }

  let(:file_double) {double}

  # describe "#index" do

  # end

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
    before do
      allow(file_double.to_s).to receive(:send).with(:content_type).and_return('text/csv')
      allow(file_double.to_s).to receive(:send).with(:original_filename).and_return(file_location)
      allow(file_double.to_s).to receive(:send).with(:tempfile).and_return(file_location)
    end
    it "should successfully create a seed record from a CSV with all of the attributes from the CSV assigned to seed rows" do
      return unless file_location.present?
      # because it uploads a file from the UI, it will be a bit different format.
      # TODO: Look up the API for this and mock it here better
      post :create, params: {file: file_double}
      expect(response).to redirect_to(edit_exchanges_seed_path(latest_seed.id))
      expect(Seeds::Seed.count).to be > 0
      expect(Seeds::Seed.first.rows.count).to be > 0
    end
    context "CSV format" do
      xit "should show an error to user if type uploaded is not a CSV" do

      end

      xit "should show an error to user if CSV contains incorrect headers" do

      end
    end
  end
  describe "#edit" do
    it "should render the edit page when seed id is passed" do
      get :edit, params: {id: latest_seed.id}, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("")
    end
  end

  describe "#update" do
    it "should begin to process the seed in the background" do
      return unless file_location.present?
      post :create, params: create_params
      put :update, params: update_params
      expect(response).to redirect_to(edit_exchanges_seed_path(latest_seed.id))
      expect(flash[:notice]).to eq(l10n("seeds_ui.begin_seed_message"))
    end
  end
end
