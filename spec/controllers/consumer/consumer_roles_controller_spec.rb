require 'rails_helper'

RSpec.describe Consumer::ConsumerRolesController, :type => :controller do
  let(:user){ double("User", email: "test@example.com") }
  let(:person){ double("Person") }
  let(:consumer_role){ double("ConsumerRole", id: double("id")) }

  context "GET new" do
    before(:each) do
      allow(user).to receive(:build_person).and_return(person)
      allow(controller).to receive(:build_nested_models).and_return(true)
    end
    it "should render new template" do
      sign_in user
      get :new
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  context "POST create" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"000000111","user_id"=>"xyz"}}
    before(:each) do
      allow(Person).to receive(:new).and_return(person)
      allow(person).to receive(:build_consumer_role).and_return(consumer_role)
      allow(person).to receive(:save).and_return(true)
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
      allow(controller).to receive(:build_nested_models).and_return(true)
      allow(user).to receive(:person).and_return(person)
    end
    it "should render new template" do
      sign_in user
      get :edit, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end


end

