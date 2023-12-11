# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::SanitizeHelper, type: :helper, dbclean: :after_each do
  include BenefitSponsors::SanitizeHelper

  describe '#sanitize' do
    it 'returns empty strings when executable script is passed' do
      expect(sanitize('&#00;</form><input type&#61;"date" onfocus="alert(1)">')).to eq ""
    end

    it 'removes additional script in the string' do
      expect(sanitize('&#00;random text</form><input type&#61;"date" onfocus="alert(1)">')).to eq "random text"
    end

    it 'returns value if it is valid' do
      expect(sanitize('random text')).to eq 'random text'
    end

    it 'returns date correctly' do
      expect(sanitize(TimeKeeper.date_of_record.to_s)).to eq TimeKeeper.date_of_record.to_s
    end

    it 'returns value unless it is a string' do
      expect(sanitize(123_456)).to eq 123_456
    end
  end
end