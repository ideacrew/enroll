require 'rails_helper'

describe Forms::QleForms::QleForm do
  let(:params) do
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
  let(:qle_form_create) { Forms::QleForms::QleForm.for_create(params) }
  let(:qle_form_update) { Forms::QleForms::QleForm.for_update(params) }
  let(:existing_qle) do
    FactoryBot.create(
      :qualifying_life_event_kind,
      title: "Got a New Dog",
      tool_tip: "Household has a dog for no reason"
    )
  end

  it "should successfully create the QLEKind record" do
    qle_form_create
    expect(QualifyingLifeEventKind.all.to_a.count).to_not eq(0)
    expect(QualifyingLifeEventKind.first.title).to eq("Got a New Dog")
  end

  it "should successfully update an existing QLEKind record" do
    expect(existing_qle.tool_tip).to eq("Household has a dog for no reason")
    qle_form_update
    existing_qle.reload
    qle_title = "Got a New Dog"
    existing_qle = QualifyingLifeEventKind.where(title: qle_title).first
    expect(existing_qle.reload.tool_tip).to eq("Household adds a new dog for emotional support")
  end
end



