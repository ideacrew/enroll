require 'rails_helper'

describe "shared/_alph_paginate_remote.html.erb" do

  context "ALL link to be added" do

    context "url_params are present" do
      let(:url_params) { {"id":"12345678", "profile_id":"987654321"} }
      it "adds url_params to href url" do
        render "shared/alph_paginate_remote", url: family_index_broker_agencies_profiles_path, alphs: [],
               all: family_index_broker_agencies_profiles_path, url_params: url_params
        expect(rendered).to have_link("ALL", href:"/broker_agencies/profiles/family_index?id=12345678&profile_id=987654321")
      end

    end

    context "url_params are absent" do
      let(:url_params) { nil }
      it "adds url_params to href url" do
        render "shared/alph_paginate_remote", url: family_index_broker_agencies_profiles_path, alphs: [],
               all: family_index_broker_agencies_profiles_path, url_params: url_params
        expect(rendered).to have_link("ALL", href:"/broker_agencies/profiles/family_index")
      end
    end
  end
end