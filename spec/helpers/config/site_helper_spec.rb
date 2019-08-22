require "rails_helper"

RSpec.describe Config::SiteHelper, :type => :helper, dbclean: :after_each do

  describe "Site settings" do

    context '.site_copyright_period_start' do
      
      it 'should return copyright period start year' do
        expect(helper.site_copyright_period_start).to be_kind_of(String)
      end
    end
    
    context '.site_help_url' do
      
      it 'should return help url' do
        expect(helper.site_copyright_period_start).to be_kind_of(String)
      end
    end

    context '.site_business_resource_center_url' do

      it 'should return business resource center url' do 
        expect(helper.site_business_resource_center_url).to be_kind_of(String)
      end
    end

    context '.site_nondiscrimination_notice_url' do

      it 'should return non discrimination notice url' do
        expect(helper.site_nondiscrimination_notice_url).to be_kind_of(String)
      end
    end

    context '.site_policies_url' do

      it 'should return site policies url' do
        expect(helper.site_policies_url).to be_kind_of(String)
      end
    end

    context '.site_faqs_url' do

      it 'should return site faqs url' do
        expect(helper.site_faqs_url).to be_kind_of(String)
      end
    end
  end
end
