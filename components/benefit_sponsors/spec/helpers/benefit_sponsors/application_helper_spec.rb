require 'spec_helper'

describe BenefitSponsors::ApplicationHelper do

  describe '.profile_unread_messages_count' do
    let(:inbox) { double('inbox', unread_messages: [1], unread_messages_count: 2 )}
    let(:profile) { double('Profile', inbox: inbox)}

    context 'when profile is an instance of BenefitSponsors::Organizations::Profile then' do
      before do
        expect(profile).to receive(:is_a?).and_return(true)
      end
      it { expect(helper.profile_unread_messages_count(profile)).to eq(1) }
    end

    context 'when profile is not an instance of BenefitSponsors::Organizations::Profile then' do
      before do
        expect(profile).to receive(:is_a?).and_return(false)
      end
      it { expect(helper.profile_unread_messages_count(profile)).to eq(2) }
    end

    context 'when there is an error then' do
      let(:wrong_profile) { double('Profile')}

      it { expect(helper.profile_unread_messages_count(wrong_profile)).to eq(0) }
    end
  end
end