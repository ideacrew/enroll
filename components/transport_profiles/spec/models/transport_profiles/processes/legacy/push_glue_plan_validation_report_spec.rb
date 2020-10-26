# frozen_string_literal: true

require "rails_helper"

module TransportProfiles
  describe Processes::Legacy::PushGluePlanValidationReport, "provided a file and a gateway" do
    let(:report_file_name) { double }
    let(:gateway) { double }
    let(:d_file_name) { double }
    let(:s_credentials) { double }

    subject { Processes::Legacy::PushGluePlanValidationReport.new(report_file_name, gateway,destination_file_name: d_file_name, source_credentials: s_credentials) }

    it "has 2 steps" do
      expect(subject.steps.length).to eq 2
    end

    it "has 2 step_descriptions" do
      expect(subject.step_descriptions.length).to eq 2
    end
  end
end

