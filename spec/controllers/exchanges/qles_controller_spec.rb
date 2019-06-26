require 'rails_helper'

RSpec.describe Exchanges::QlesController, :type => :controller do
  let(:qle_creation_params) do
    {
      "title"=>"Got a New Dog",
      "event_kind_label"=>"Date of birth",
      "market_kind" => "shop",
      "effective_on_kinds" => ["date_of_event"],
      "tool_tip"=>"Household adds a new dog for emotional support",
      "reason"=>"birth",
      "pre_event_sep_in_days" => "1",
      "post_event_sep_in_days" => "1",
      "questions_attributes"=> {
        "0"=> {
          "content"=>"When was Your Dog Born?",
          "answer_attributes"=> {
            "responses_attributes"=> {
                "0"=>{
                  "name"=>"true",
                  "result"=>"contact_call_center"
              },
            "1"=>{
              "name"=>"false",
              "result"=>"contact_call_center"
              },
            "2"=>{
              "operator"=>"before",
              "value"=>"",
              "value_2"=>""
            },
            "3"=>{
              "name"=>"",
              "result"=>"proceed"
            }
          }
        },
        "type"=>"date"
      }
    },
    "start_on"=>"06/01/1990",
    "end_on"=>"06/01/2005"
    }
  end
    let(:new_qle_params) do
    {
      "action"=>"create_manage_qle",
      "controller"=>"qles",
      "manage_qle"=>{
        "action"=>"new_qle"
      }
    }
  end
  let(:modify_qle_params) do
    {
      "action"=>"create_manage_qle",
      "controller"=>"qles",
      "manage_qle"=>{
        "action"=>"modify_qle"
      }
    }
  end
  let(:deactivate_qle_params) do
    {
      "action"=>"create_manage_qle",
      "controller"=>"qles",
      "manage_qle"=>{
        "action"=>"deactivate_qle"
      }
    }
  end
  let(:manage_qle_new_instance) { ::Forms::ManageQleForm.for_create(new_qle_params) }
  let(:manage_qle_modify_instance) { ::Forms::ManageQleForm.for_create(modify_qle_params) }
  let(:manage_qle_deactivate_instance) { ::Forms::ManageQleForm.for_create(deactivate_qle_params) }
  let(:user) { FactoryBot.create(:user) }
  let(:existing_qle) do
    FactoryBot.create(
      :qualifying_life_event_kind,
      title: "Got a New Dog",
      tool_tip: "Household has a dog for no reason"
    )
  end

  before :each do
    sign_in(user)
  end

  describe "GET #new_manage_qle" do
    it "successfully renders the new manage qle form" do
      get :new_manage_qle
      expect(response.status).to eq(200)  
    end
  end

  describe "GET #new" do
    it "successfully renders the new page" do
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe "POST #create" do
    
  end

  describe "POST #create_manage_qle" do
    before :each do
      # TODO: Assure that it should be "shop" for market kind
      allow_any_instance_of(::Forms::ManageQleForm).to receive(:market_kind).and_return("shop")
    end

    context "successfully redirects to" do
      it "new" do
        allow(::Forms::ManageQleForm).to receive(:for_create).with(new_qle_params).and_return(manage_qle_new_instance)
        post :create_manage_qle, params: { manage_qle: { action: "new_qle" } }
        expect(response.status).to eq(200)
      end

      it "modify" do
        allow(::Forms::ManageQleForm).to receive(:for_create).with(modify_qle_params).and_return(manage_qle_modify_instance)
        post :create_manage_qle, params: { manage_qle: { action: "modify_qle" } }
        expect(response.status).to eq(200)
      end

      it "deactivate" do
        allow(::Forms::ManageQleForm).to receive(:for_create).with(deactivate_qle_params).and_return(manage_qle_deactivate_instance)
        post :create_manage_qle, params: { manage_qle: { action: "deactivate_qle" } }
        expect(response.status).to eq(200)
      end
    end
  end
end
