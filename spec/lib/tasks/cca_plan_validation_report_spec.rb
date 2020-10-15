# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'rubyXL'
require 'rubyXL/convenience_methods'

describe 'reports generation after plan loading', :dbclean => :after_each do

  let(:current_date) {Date.today.strftime("%Y_%m_%d")}
  let(:file_name) {"#{Rails.root}/CCA_PlanLoadValidation_Report_EA_#{current_date}.xlsx"}

  before do
    load File.expand_path("#{Rails.root}/lib/tasks/cca_plan_validation_report.rake", __FILE__)
    Rake::Task.define_task(:environment)
    allow(Date).to receive(:today).and_return Date.new(2001,2,3)
  end

  context 'generation of reports' do
    after :all do
      File.delete(File.join("#{Rails.root}/", "CCA_PlanLoadValidation_Report_EA_2001_02_03.xlsx")) if File.file?(File.join("#{Rails.root}/", "CCA_PlanLoadValidation_Report_EA_2001_02_03.xlsx"))
    end

    it 'should generate a xlsx when active date is passed' do
      ClimateControl.modify active_date: "2019-12-01" do
        Rake::Task["cca_plan_validation:reports"].invoke
        expect(File.exist?(file_name)).to be true
      end
    end

    context 'first sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet = workbook[0]
        worksheet.sheet_data[0]
        expect(worksheet.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "PlanTypeCode", "Tier", "Count"]
      end
    end

    context 'second sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet1 = workbook[1]
        worksheet1.sheet_data[0]
        expect(worksheet1.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "RatingArea", "Age(Range)", "IndividualRate"]
      end
    end

    context 'third sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet2 = workbook[2]
        worksheet2.sheet_data[0]
        expect(worksheet2.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "ServiceAreaCode", "PlanCount", "County_Count", "Zip_Count"]
      end
    end

    context 'fourth sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet3 = workbook[3]
        worksheet3.sheet_data[0]
        expect(worksheet3.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "GroupSizeSum", "GroupSizeFactorSum"]
      end
    end

    context 'fifth sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet4 = workbook[4]
        worksheet4.sheet_data[0]
        expect(worksheet4.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "GroupSizeSum", "ParticipationRateSum"]
      end
    end
    context 'sixth sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet5 = workbook[5]
        worksheet5.sheet_data[0]
        expect(worksheet5.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "SIC_Count", "SICRateSum"]
      end
    end
    context 'seventh sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet6 = workbook[6]
        worksheet6.sheet_data[0]
        expect(worksheet6.sheet_data[0].cells.map(&:value)).to eq ["CarrierId", "CarrierName", "ProductModel", "PlanCount"]
      end
    end
    context 'eighth sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet7 = workbook[7]
        worksheet7.sheet_data[0]
        expect(worksheet7.sheet_data[0].cells.map(&:value)).to eq ["CarrierId", "CarrierName", "HIOS_ID", "Renewal_HIOS_ID"]
      end
    end

    context 'ninth sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet8 = workbook[8]
        worksheet8.sheet_data[0]
        expect(worksheet8.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "HIOS_Plan_ID", "SG_ID"]
      end
    end
  end
end
