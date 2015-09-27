require 'rails_helper'

RSpec.describe Insured::ConsumerRolesController, :type => :controller do
  let(:user){ double("User", email: "test@example.com") }
  let(:person){ double("Person") }
  let(:family){ double("Family") }
  let(:family_member){ double("FamilyMember") }
  let(:consumer_role){ double("ConsumerRole", id: double("id")) }
  let(:bookmark_url) {'localhost:3000'}
  describe "Get search" do
    let(:user) { double("User" ) }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", ssn: "333224444", dob: "08/15/1975") }

    before(:each) do
      sign_in user
      allow(Forms::EmployeeCandidate).to receive(:new).and_return(mock_employee_candidate)
      allow(user).to receive(:has_consumer_role?).and_return(false)
      allow(user).to receive(:last_portal_visited=)
      allow(user).to receive(:save!).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(consumer_role).to receive(:save!).and_return(true)
    end

    it "should render search template" do
      get :search
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)
    end

    it "should set the session flag for aqhp the param exists" do
      get :search, aqhp: true
      expect(session[:individual_assistance_path]).to be_truthy
    end

    it "should unset the session flag for aqhp if the param does not exist upon return" do
      get :search, aqhp: true
      expect(session[:individual_assistance_path]).to be_truthy
      get :search, uqhp: true
      expect(session[:individual_assistance_path]).to be_falsey
    end

  end

  describe "GET match" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:mock_consumer_candidate) { instance_double("Forms::ConsumerCandidate", :valid? => validation_result, ssn: "333224444", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname") }
    let(:user_id) { "SOMDFINKETHING_ID"}
    let(:found_person){ [] }
    let(:person){ instance_double("Person") }
    let(:user) { double("User",id: user_id, :idp_verified? => false) }

    before(:each) do
      sign_in(user)
      allow(mock_consumer_candidate).to receive(:match_person).and_return(found_person)
      allow(Forms::ConsumerCandidate).to receive(:new).with(person_parameters.merge({user_id: user_id})).and_return(mock_consumer_candidate)
      get :match, :person => person_parameters
    end

    context "given invalid parameters" do
      let(:validation_result) { false }
      let(:found_person) { [] }

      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
      end
    end

    context "given valid parameters" do
      let(:validation_result) { true }

      context "but with no found employee" do
        let(:found_person) { [] }
        let(:person){ double("Person") }
        let(:person_parameters){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"000000111"}}

        it "renders the 'no_match' template" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("no_match")
          expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
        end

        context "that find a matching employee" do
          let(:found_person) { [person] }

          it "renders the 'match' template" do
            expect(response).to have_http_status(:success)
            expect(response).to render_template("match")
            expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
          end
        end
      end
    end
  end
  context "POST create" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"000000111","user_id"=>"xyz"}}
    let(:user){FactoryGirl.create(:user)}
    before(:each) do
      allow(Factories::EnrollmentFactory).to receive(:construct_employee_role).and_return(consumer_role)
      allow(consumer_role).to receive(:person).and_return(person)
    end
    it "should create new person/consumer role object" do
      sign_in user
      post :create, person: person_params
      expect(response).to have_http_status(:redirect)
    end
  end

  context "GET edit" do
    before(:each) do
      allow(ConsumerRole).to receive(:find).and_return(consumer_role)
      allow(consumer_role).to receive(:person).and_return(person)
      allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(consumer_role).to receive(:save!).and_return(true)
      allow(consumer_role).to receive(:bookmark_url=).and_return(true)
    end
    it "should render new template" do
      sign_in user
      get :edit, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end

  context "PUT update" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"468389102","user_id"=>"xyz"}}
    let(:person){ FactoryGirl.build(:person) }

    before(:each) do
      allow(ConsumerRole).to receive(:find).and_return(consumer_role)
      allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
      allow(consumer_role).to receive(:person).and_return(person)
      sign_in user
    end

    it "should update existing person" do
      allow(consumer_role).to receive(:update_by_person).and_return(true)
      allow(controller).to receive(:update_vlp_documents).and_return(true)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(ridp_agreement_insured_consumer_role_index_path)
    end

    it "should not update the person" do
      allow(controller).to receive(:update_vlp_documents).and_return(false)
      allow(consumer_role).to receive(:update_by_person).and_return(true)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "should not update the person" do
      allow(controller).to receive(:update_vlp_documents).and_return(false)
      allow(consumer_role).to receive(:update_by_person).and_return(false)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end
end
