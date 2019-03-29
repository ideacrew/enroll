require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_sep_market_kind")

describe UpdateSepMarketKind, dbclean: :after_each do

  let(:given_task_name) { "update_sep_market_kind" }
  subject { UpdateSepMarketKind.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe "update sep invalid records", dbClean: :after_each do
    let!(:person100)  { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
    let!(:primary_applicant) { double }
    let!(:family100)  { FactoryGirl.create(:family, :with_primary_family_member, person: person100 ) }
    let(:special_enrollment_period) {FactoryGirl.build(:special_enrollment_period,family:family100,qualifying_life_event_kind_id: qualifying_life_event_kind101.id, market_kind: "ivl")}
    let!(:add_special_enrollment_period) {family100.special_enrollment_periods = [special_enrollment_period]
                                          family100.save
    }
    let!(:qualifying_life_event_kind101)  { FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop") }

    context 'update sep market kind to shop', dbclean: :after_each  do
      
      before(:each) do
        allow(person100).to receive(:has_active_employee_role?).and_return(true)
        special_enrollment_period.save(validate:false)
      end

      it "should update market kind" do
        subject.migrate
        expect(special_enrollment_period.update_attributes(market_kind: "shop")).to eq true
      end
    end

    context 'not update sep market kind to ivl', dbclean: :after_each  do
      
      before(:each) do
        special_enrollment_period.qualifying_life_event_kind.update_attributes(market_kind: "ivl")
        allow(person100).to receive(:has_active_employee_role?).and_return(true)
      end

      it "should remain market kind to ivl" do
        subject.migrate
        expect(special_enrollment_period.market_kind).to eq "ivl"
      end
    end
  end
end
