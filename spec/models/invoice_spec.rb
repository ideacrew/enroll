require 'rails_helper'

RSpec.describe Invoice, type: :model do
  
  let(:invoice) { FactoryGirl.create(:invoice) }
  let(:org) { FactoryGirl.create(:organization) }
  let(:file_path){ "test/hbxid_01012001_invoice_R.pdf"}
  let(:valid_file_names){ ["hbxid_01012001_invoice_R.pdf","hbxid_04012014_invoice_R.pdf","hbxid_10102001_invoice_R.pdf"] }
  
  before do
  	allow(Aws::S3Storage).to receive(:save).and_return("urn:openhbx:terms:v1:file_storage:s3:bucket:invoice:asdds123123")
  	allow(Invoice).to receive(:get_organization).and_return(org)
  end

  context "Invoice Upload" do
    context "with valid arguments" do
    	before do
    		Invoice.upload_invoice(file_path)
    	end
    	 it "should upload invoice to the organization" do
        expect(org.invoices.count).to eq 1
      end
    end
    context "with duplicate files" do
    	before do
    		Invoice.upload_invoice(file_path)
    		Invoice.upload_invoice(file_path)
    	end
    	 it "should upload invoice to the organization only once" do
        expect(org.invoices.count).to eq 1
      end
    end

    context "without date in file name" do
    	before do
    		Invoice.upload_invoice('dummyfile.pdf')
    	end
    	 it "should Not Upload invoice" do
        expect(org.invoices.count).to eq 0
      end
    end
  end

 	context "get_invoice_date" do 
 		context "with valid date in the file name" do
 			it "should parse the date" do
 				valid_file_names.each do | file_name |
 					expect(Invoice.get_invoice_date(file_name)).to  be_an_instance_of(Date)
 				end
 			end
 		end
 	end

end
