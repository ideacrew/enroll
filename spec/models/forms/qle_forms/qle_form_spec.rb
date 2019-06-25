require 'rails_helper'

describe Forms::QleForms::QleForm do
  let(:for_create_params) do
    {
      "title"=>"",
      "event_kind_label"=>"",
      "tool_tip"=>"",
      "reason"=>"",
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
  let(:qle_form_create) { Forms::QleForms::QleForm.for_create(for_create_params) }

  it "should successfully create the QLE object" do
    qle_form_create
    expect(QualifyingLifeEvent.all.to_a).to eq > 0
  end
end