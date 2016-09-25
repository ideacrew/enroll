require 'rails_helper'

RSpec.describe Factories::Types::Base, type: :model do
  let(:person_template)             { Person.new.attributes.except("_id", "version") }
  let(:consumer_role_template)      { person_template.buiild.attributes.except("_id", "version") }
  let(:family_transcript_template)  { }

  describe "instance methods" do
    let(:family_transcript)    { Factories::FamilyTranscript.new }
    let(:base_array)           { base_hash.merge({game_shows: %w(jeopardy password gong_show)}) }
    let(:compare_array)        { base_hash.merge({game_shows: %w(jeopardy password truth_or_consequences)}) }
    let(:base_hash)            { {first_name: "Tina", last_name: "Fey", occupation: "comedian"} }
    let(:occupation_update)    { {first_name: "Tina", last_name: "Fey", occupation: "actress"} }
    let(:multi_update)         { {first_name: "Christina", last_name: "Fey", occupation: "actress", } }
    let(:occupation_dropped)   { {"remove"=>{"occupation"=>"comedian"}} }
    let(:last_name_added)      { {"add"=>{"last_name"=>"Fey"}} }
    let(:occupation_updated)   { {"update"=>{"occupation"=>"actress"}} }
    let(:multi_updated)        { {"update"=>{"first_name"=>"Christina", "occupation"=>"actress"}} }
    let(:array_changes)        { {"array"=>{"game_shows"=>{"add"=>["truth_or_consequences"], "remove"=>["gong_show"]}}} }
    let(:array_added)          { {"add"=>{"game_shows"=>["jeopardy", "password", "gong_show"]}} }

    context "#compare" do
      context "and identical records are compared" do
        it "should return empty hash" do
          expect(family_transcript.compare(base_hash, base_hash)).to eq Hash.new
        end

        context "and the identical records contain an array" do
          it "should return empty hash" do
            expect(family_transcript.compare(base_array, base_array)).to eq Hash.new
          end
        end
      end

      context "and the base record has a value missing from the compare record" do
        it "should return a remove for that key" do
          expect(family_transcript.compare(base_hash, base_hash.except(:occupation))).to eq occupation_dropped
        end
      end

      context "and the compare record has a value missing from the base record" do
        it "should return an add for that key" do
          expect(family_transcript.compare(base_hash.except(:last_name), base_hash)).to eq last_name_added
        end
      end

      context "and the compare record updates a base record value" do
        it "should return an update for that key" do
          expect(family_transcript.compare(base_hash, occupation_update)).to eq occupation_updated
        end
      end

      context "and multiple values are updated between the base and compare records" do
        it "should return an update for multiple keys" do
          expect(family_transcript.compare(base_hash, multi_update)).to eq multi_updated
        end

        context "and an array is added" do
          it "should return an update with the new array" do
            expect(family_transcript.compare(base_hash, base_array)).to eq array_added
          end
        end
 
        context "and the records contain an array with changes" do
          it "should return an update for multiple keys" do
            expect(family_transcript.compare(base_array, compare_array)).to eq array_changes
          end
        end
      end
    end

    context "#copy_properties" do
    end

    context "#copy_property" do
    end
  end
end
