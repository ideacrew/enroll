require 'rails_helper'

describe Aws::S3Storage do

  #allow(:storage_double) {double}
  #allow(Aws::S3Strorage).to receive(:new).and_respond_with(storage_double)
  let(:subject) { Aws::S3Storage.new }
  let(:object) { double }
  let(:bucket_name) { 'test-bucket' }
  let(:file_path) { File.dirname(__FILE__) }
  let(:key) { SecureRandom.uuid }
  let(:uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket:<#{bucket_name}>##{key}" }

  context "with explicit key" do
    context "success" do
      it 'return the URI of saved file' do
        allow(object).to receive(:upload_file).with(file_path).and_return(true)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect(subject.save(file_path, bucket_name, key)).to eq(uri)
      end
    end
  end


  context "without explicit key" do
    context "success" do
      it 'return the URI of saved file' do
        allow(object).to receive(:upload_file).with(file_path).and_return(true)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect(subject.save(file_path, bucket_name)).to include("urn:openhbx:terms:v1:file_storage:s3:bucket:")
      end
    end
  end
end