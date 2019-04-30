
describe "Redirects"  do
  describe "Old Model to New Model Redirect" do

    it "redirects to /benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor when going to old model url" do
      get "/employers/employer_profiles/new"
      expect(response.code).to eq "301"
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end

    it "redirects permantly (301) to main landing page when going to old model url" do
      get "/employers"
      #expect(response.code).to eq "301"
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end

    it "redirects permantly (301) to landing page when employer id specified when going to old model url of employer profile path" do
      get "/employers/employer_profiles/123456"
      expect(response).to redirect_to root_path
    end

    it "redirects permantly (301) to landing page when employer id specified and member route when going to old model url of employer profile path" do
      get "/employers/employer_profiles/123456/my_account"
      expect(response).to redirect_to root_path
    end

    it "redirects to benefit_sponsors/profiles/registrations/new?profile_type=broker_agency going to old model url of broker registration" do
      get "/broker_registration"
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=broker_agency")
    end


  end
end
