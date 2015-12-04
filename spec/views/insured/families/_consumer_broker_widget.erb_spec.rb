# require 'rails_helper'
#
# RSpec.describe "_consumer_broker_widget.html.erb" do
#
#   context 'insured home broker widget as consumer' do
#     let(:consumer_role) { FactoryGirl.build(:consumer_role) }
#     let(:person) { FactoryGirl.build(:person, consumer_role: consumer_role) }
#     let(:family) { FactoryGirl.build(:family, :with_primary_family_member, person: person) }
#     let(:family_member) { family.family_members.last }
#
#     before :each do
#       assign(:person, person)
#       assign :family_members, [family_member]
#       render :partial => 'insured/families/consumer_broker_widget'
#     end
#
#     it "should be a success" do
#       allow(family_member).to receive(:person).and_return person
#       expect(response).to have_http_status(:success)
#     end
#
#     it "should display broker widget for consumer" do
#       expect(rendered).to have_selector('h4', "Your Broker")
#     end
#
#   end
#
# end
