require "rails_helper"

describe QleKinds::CreateDomainValidator do
  let(:user) { instance_double(User) }
  let(:request) { instance_double(Admin::QleKinds::CreateRequest, title: request_title) }
  let(:service) { instance_double(Admin::QleKinds::CreateService) }
  let(:request_title) { "A REQUEST TITLE" }

  subject { QleKinds::CreateDomainValidator.new }

  describe "given valid objects" do
    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(true)
    end

    it "is valid" do
      expect(subject.call(user: user, request: request, service: service).success?).to be_truthy
    end
  end

  describe "given a qle create request with a duplicate title" do

    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(false)
    end

    it "is invalid" do
      validation_result = subject.call(user: user, request: request, service: service)
      expect(validation_result.errors.to_h).to have_key(:duplicate_title)
    end
  end
end