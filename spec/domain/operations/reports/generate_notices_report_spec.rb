# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Reports::GenerateNoticesReport, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person)}
  let(:document) { Document.new(title: "Your Eligibility Results Consent or Missing Information Needed") }

  before :each do
    person.documents << document
    Dir.glob("#{Rails.root}/notices_list_*.csv").each do |file|
      FileUtils.rm(file)
    end
  end

  context 'generate notices report' do
    before do
      Operations::Reports::GenerateNoticesReport.new.call({})
      @file_content = File.read("#{Rails.root}/notices_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv")
    end

    it 'should include person hbx id in the report' do
      expect(@file_content).to include(person.hbx_id)
    end

    it 'should include notice title in the report' do
      expect(@file_content).to include(document.title)
    end

    it 'should include notice code in the report' do
      expect(@file_content).to include("IVL_OEG")
    end

    it 'should include notice created_at in the report' do
      expect(@file_content).to include(person.documents.first.created_at.to_s)
    end
  end
end
