require 'rails_helper'
require 'net/http'

module TransportGateway
  RSpec.describe Gateway, type: :model do

    let(:sftp_uri)      { URI("sftp://foo:bar@sftp.example.com/path/to/file;type=b") } 
    let(:binary_file)   {  }


    context "A common interface for sending messages with payloads using various protocols" do

      context "when a Gateway is initialized" do

        it "should load an SFTP adapter" do
          expect(Gateway.new().adapters).to include(:sftp_adapter)
        end

        it "should load an HTTP adapter" do
          expect(Gateway.new().adapters).to include(:http_adapter)
        end

        it "should load an File adapter" do
          expect(Gateway.new().adapters).to include(:file_adapter)
        end

        it "should load an AWS S3 adapter" do
          expect(Gateway.new().adapters).to include(:s3_adapter)
        end


        context "and the message source is a File" do
          let(:source_file_path)    { File.join(File.expand_path("../../..", __FILE__), "test_files", "text_file.txt") }
          let(:source_file_handle)  { File.new(source_file_path) }
          let(:source_file_data)    { File.read(source_file_path) }

          it "should find the test file with the expected contents" do
            expect(File.read(source_file_path)).to eq source_file_data
          end

          context "and the message is sent using HTTP protocol" do
            let(:target_host)       { "www.example.com" }
            let(:target_service)    { "/path/to/target/service" }
            let(:target_user)       { "foo" }
            let(:target_password)   { "secret_password" }
            let(:target_userinfo)   { target_user + ':' + target_password }
            let(:scheme)            { "http"}

            let(:from)              { source_file_handle }
            let(:to)                { URI::Generic.build({ scheme: scheme, host: target_host, path: target_service, userinfo: target_userinfo }) } 
            let(:message)           { Message.new(from: from, to: to) }

            before(:each) do
              stub_request(:put, /www.example.com/).to_return(status: 200, body: "http stubbed response", headers: {})
            end

            it "should successfully send the file, returning a HTTP success status" do
              expect(Gateway.new().send_message(message)).to be_kind_of Net::HTTPSuccess
            end
          end

          context "and a message is sent using SMTP protocol" do
          end

          context "and a message is sent using File protocol" do
          end

          context "and a message is sent using S3 protocol" do
          end

          context "and a message is sent with unsupported protocol" do
            let(:target_host)       { "www.example.com" }
            let(:target_service)    { "/path/to/target/service" }
            let(:target_user)       { "foo" }
            let(:target_password)   { "secret_password" }
            let(:bogus_protocol)    { "dljkafklejawfkladf" }
            let(:to)                { URI::Generic.build({ scheme: bogus_protocol, host: target_host, path: target_service}) } 
            let(:message)           { Message.new(from: nil, to: to) }

            let(:gateway) { Gateway.new }

            it "should raise an error" do
              expect { gateway.send_message(message) }.to raise_error(URI::BadURIError, "unsupported scheme: #{bogus_protocol}")
            end
          end

        end
      end

    end
  end
end
