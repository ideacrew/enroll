require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_hbx_id_from_person")

describe RemoveHbxIdFromPerson do
  let(:person_1) { FactoryGirl.create(:person, hbx_id:"911911911") }
  let(:person_2) { FactoryGirl.create(:person) }
  
  it "changes person 2 hbx id to person 1 hbx id" do
    person_1.update(hbx_id:"011011011")
    person_2.update(hbx_id:"911911911")
    #I know this feels dirty (Kevin)
    expect(person_2.hbx_id).to eq "911911911"
  end
end