require 'rails_helper'
require Rails.root.join('lib', 'tasks', 'hbx_import', 'broker', 'parsers', 'broker_parser')

describe Parser::BrokerParser do

  before(:all) do
    xml = Nokogiri::XML(File.open(Rails.root.join('spec', 'test_data', 'NewBrokerFile.xml')))
    @brokers = Parser::BrokerParser.parse(xml.root.canonicalize).map(&:to_hash)   
  end

  it 'should parse 2 brokers from xml' do
    expect(@brokers.length).to eq(2)
  end
  it 'should extracts person name fields from xml' do
    expect(@brokers.first[:name][:first_name]).to eq('Ellen')
    expect(@brokers.first[:name][:last_name]).to eq('Cool')
  end

  it 'should extracts email field' do
    expect(@brokers.first[:emails].first[:kind]).to eq('work')
    expect(@brokers.first[:emails].first[:address]).to eq('nice.person@gmail.com')
  end


  it 'should extracts phone field' do
    expect(@brokers.first[:phones].first[:kind]).to eq('work')
    expect(@brokers.first[:phones].first[:full_phone_number]).to eq('+1-100-728-5005')

  end

  it 'should extracts broker fields' do
    expect(@brokers.first[:npn]).to eq('14636000')
  end
end
