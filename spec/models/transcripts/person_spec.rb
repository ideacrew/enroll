require 'rails_helper'

RSpec.describe Transcripts::PersonTranscript, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"

  let(:person_template)             { Person.new.attributes.except("_id", "version") }
  let(:consumer_role_template)      { person_template.buiild.attributes.except("_id", "version") }
  let(:family_transcript_template)  { }

  describe "instance methods" do

    let!(:source_record) {
      Person.create({ 
        "hbx_id"=>"117966",
        "first_name"=>"Bruce",
        "last_name"=>"Jackson",
        "dob"=> Date.new(1975, 8, 1),
        "gender"=>"male",
        "middle_name"=>"",
        "ssn"=>"671126612",
        "no_dc_address"=>false,
        "addresses"=>[{
          "kind"=>"home",
          "address_1"=>"3312 H St NW",
          "city"=>"Washington",
          "state"=>"DC",
          "zip"=>"20002"
          }],
          "phones"=>[{
            "area_code"=>"202",
            "kind"=>"mobile",
            "full_phone_number"=>"2029867777",
            "number"=>"9867777",
            }],
            "emails"=>[{"kind"=>"home", "address"=>"bruce@gmail.com"}]
          })
    }

    let(:other_record) {
      Person.new({"hbx_id"=>"117966",
        "first_name"=>"Bruce",
        "last_name"=>"Jackson",
        "dob"=> Date.new(1975, 6, 1),
        "gender"=>"male",
        "middle_name"=>"",
        "ssn"=>"671126612",
        "no_dc_address"=>false,
        "addresses"=>[{
          "kind"=>"work",
          "address_1"=>"3312 K St NW",
          "city"=>"Washington",
          "state"=>"DC",
          "zip"=>"20008"
          }],
        "phones"=>[{
            "area_code"=>"202",
            "kind"=>"home",
            "full_phone_number"=>"2029866677",
            "number"=>"9866677",
          }],
          "emails"=>[{"kind"=>"home", "address"=>"bruce@gmail.com"}]
        })
    }

    context "#compare" do

      it 'should return differences' do 
        builder = Transcripts::PersonTranscript.new
        builder.find_or_build(other_record)
        person_transcript = builder.transcript

        expect(person_transcript[:source]).to eq source_record
        expect(person_transcript[:other]).to eq other_record
        expect(person_transcript[:compare][:base]['update']).to eq({'dob' => Date.new(1975, 6, 1)})
      end
    end
  end
end
