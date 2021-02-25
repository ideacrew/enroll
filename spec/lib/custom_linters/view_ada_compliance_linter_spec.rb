# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/custom_linters/ada_compliance/view_ada_compliance_linter.rb"

RSpec.describe ViewAdaComplianceLinter do
  let(:compliance_rules_hash) do
    # TODO: Move this to config
    YAML.load_file("#{Rails.root}/lib/custom_linters/ada_compliance/tag_compliance_value_pairs.yml").with_indifferent_access
  end

  context "all configured attributes are unique" do
    let(:input_string) do
      "
        <input type='text' id='name' name='name' required minlength='4' maxlength='8' size='10'>
        <input type='text' id='name_1' name='name_1' required minlength='4' maxlength='8' size='10'>
        <input type='text' placeholder='name_3'>
      "
    end

    let(:linter_unique_attributes) { ViewAdaComplianceLinter.new({fake_view: input_string}, compliance_rules_hash) }

    it "should be ADA compliant" do
      expect(linter_unique_attributes.views_ada_compliant?).to eq(true)
    end
  end

  context "some configured attributes are not unique" do
    let(:input_string) do
      "
        <input type='text' id='fakeid' name='fakename' required minlength='4' maxlength='8' size='10'>
        <input type='text' id='fakeid' name='fakename' required minlength='4' maxlength='8' size='10'>
      "
    end

    let(:linter_non_unique_attributes) { ViewAdaComplianceLinter.new({fake_view: input_string}, compliance_rules_hash) }

    it "should not be ADA compliant" do
      expect(linter_non_unique_attributes.views_ada_compliant?).to eq(false)
    end
  end

  context "links do not have unique text" do
    let(:html_string) do
      "
        <a href='http://www.rubyonrails.org'>Ruby on Rails</a>
        <a href='http://www.rubyonrails.org'>Ruby on Rails</a>
      "
    end
    let(:ada_compliance_linter) { ViewAdaComplianceLinter.new({fake_view: html_string}, compliance_rules_hash) }
    it "should not be ADA compliant" do
      expect(ada_compliance_linter.views_ada_compliant?).to eq(false)
    end
  end

  context "links do have unique text" do
    let(:html_string) do
      "
        <a href='http://www.rubyonrails.org'>Ruby on Rails</a>
        <a href='http://www.google.com'>Google</a>
        <a href='http://wikipedia.org'></a>
      "
    end
    let(:ada_compliance_linter) { ViewAdaComplianceLinter.new({fake_view: html_string}, compliance_rules_hash) }
    it "should be ADA compliant" do
      expect(ada_compliance_linter.views_ada_compliant?).to eq(true)
    end
  end

  context "images alt text" do
    let(:images_string) do
      "
      <img src='img_girl.jpg' alt='An image of a girl' width='500' height='600'>
      <img src='img_dog.jpg' width='500' height='600'>
      <img src='img_pizza.jpg' alt = '' width='500' height='600'>

      "
    end

    let(:linter_no_img_alt_text) { ViewAdaComplianceLinter.new({fake_view: images_string}, compliance_rules_hash) }
    it "should not be ADA compliant if images do not have alt text" do
      expect(linter_no_img_alt_text.views_ada_compliant?).to eq(false)
    end
  end

  context "tables properly scoped" do
    let(:non_compliant_tables_string) do
      '
      <table>
      <caption>Shellys Daughters</caption>

      <tr>
      <th >Name</th>
      <th scope="col">Age</th>
      <th scope="col">Birthday</th>
      </tr>

      <tr>
      <th scope="row">Jackie</th>
      <td>5</td>
      <td>April 5</td>
      </tr>

      <tr>
      <th >Beth</th>
      <td>8</td>
      <td>January 14</td>
      </tr>

      </table>
      '
    end

    let(:table_linter_not_properly_scoped) { ViewAdaComplianceLinter.new({fake_view_10: non_compliant_tables_string}, compliance_rules_hash) }
    it "should be ADA compliant" do
      expect(table_linter_not_properly_scoped.views_ada_compliant?).to eq(false)

    end
  end

  context "tables are not properly scoped" do
    let(:proper_tables_string) do
      '
      <table>
      <caption>Shellys Daughters</caption>

      <tr>
      <th scope="col">Name</th>
      <th scope="col">Age</th>
      <th scope="col">Birthday</th>
      </tr>

      <tr>
      <th scope="row">Jackie</th>
      <td>5</td>
      <td>April 5</td>
      </tr>

      <tr>
      <th scope="row">Beth</th>
      <td>8</td>
      <td>January 14</td>
      </tr>

      </table>
    '
    end

    let(:table_linter_properly_scoped) { ViewAdaComplianceLinter.new({fake_view_10: proper_tables_string}, compliance_rules_hash) }
    it "should not be ada compliant" do
      expect(table_linter_properly_scoped.views_ada_compliant?).to eq(true)
    end
  end
end
