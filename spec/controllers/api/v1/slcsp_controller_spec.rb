require 'rails_helper'

describe Api::V1::SlcspController, :type => :controller do

  let(:request_xml) { File.read(Rails.root.join("spec", "test_data", "slcsp_payloads", "request.xml")) }
  let(:response_xml) { File.read(Rails.root.join("spec", "test_data", "slcsp_payloads", "response.xml")) }
  let(:plan) {double}

  context "valid request" do

    it 'returns https status 200' do
      allow(HappyMapper).to receive(:parse).with(anything).and_return(HappyMapper.parse(request_xml))
      allow_any_instance_of(Api::V1::SlcspController).to receive(:find_slcsp).with(anything).and_return(plan)
      allow_any_instance_of(ActionController::Rendering).to receive(:render).and_return(response_xml)

      post :plan, :format => :xml
      expect(assigns(:plan)).to eq(plan)
      assert_response :success
      # in rails 5, controller not renders views
      # when body is xml or json http_status_code will give wrong output
      # expect(response.status).to eq(200)
    end
  end

  context "invalid request" do
    it 'returns https status 422' do
      allow(HappyMapper).to receive(:parse).with(anything).and_raise(Exception.new)
      allow_any_instance_of(Api::V1::SlcspController).to receive(:find_slcsp).with(anything).and_return(plan)

      post :plan, params: { format: :xml }
      expect(response.status).to eq(422)
    end
  end
end
