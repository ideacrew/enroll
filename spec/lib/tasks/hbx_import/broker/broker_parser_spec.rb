require 'rails_helper'
require Rails.root.join('lib', 'tasks', 'hbx_import', 'broker', 'parsers', 'broker_parser')

describe Parser::BrokerParser do

  it 'should extracts broker fields from xml' do
    xml = Nokogiri::XML(File.open(Rails.root.join('spec', 'test_data', 'NewBrokerFile.xml')))
    brokers = Parser::BrokerParser.parse(xml.root.canonicalize).map(&:to_hash)
    expect(brokers.length).to eq 2
    expect(brokers.first[:name][:first_name]).to eq('Ellen')
    expect(brokers.first[:name][:last_name]).to eq('Cool')
    expect(brokers.first[:phones].first[:full_phone_number]).to eq('+1-100-728-5005')
    expect(brokers.first[:emails].first[:address]).to eq('eCool@LifeHealthHome.com')
  end
end