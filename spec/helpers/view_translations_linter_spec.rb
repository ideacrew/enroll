# frozen_string_literal: true

require 'rails_helper'
require Rails.root.to_s + "/spec/support/view_translations_linter.rb"

RSpec.describe ViewTranslationsLinter do
  context "#all_translations_present" do
    context "no filename list present" do
      let(:linter_no_filename_list) { ViewTranslationsLinter.new(nil, ["Whitelisted String"], 'in_erb')}
      it "should return true" do
        expect(linter_no_filename_list.all_translations_present?).to eq(true)
      end
    end

    context "whitelisted_translation_strings" do
      context "non whitelisted string passed" do
        let(:linter_with_non_whitelisted_string) { ViewTranslationsLinter.new(["<%= 'Non-Whitelisted String' %>"], [], 'in_erb')}
        it "should raise error" do
          expect{ linter_with_non_whitelisted_string.all_translations_present? }.to raise_exception
        end

        context "raise_error set to false" do
          let(:linter_with_non_whitelisted_string_no_errors) { ViewTranslationsLinter.new(["<%= 'Non-Whitelisted String' %>"], [], 'in_erb', false)}

          it "should return false" do
            expect(linter_with_non_whitelisted_string_no_errors.all_translations_present?).to eq(false)
          end
        end
      end

      context "whitelisted string passed" do
        let(:linter_with_whitelisted_string) { ViewTranslationsLinter.new(["<%= 'Non-Whitelisted String' %>"], ["Whitelisted String"], 'in_erb')}
        it "should return true" do
          expect(linter_with_whitelisted_string.all_translations_present?).to eq(true)
        end
      end
    end
  end
end
