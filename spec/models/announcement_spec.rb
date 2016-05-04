require 'rails_helper'

describe Announcement, dbclean: :after_each do
  describe ".new" do
    let(:valid_params) do
      {
        content: "test msg",
        start_date: TimeKeeper.date_of_record - 10.days,
        end_date: TimeKeeper.date_of_record + 10.days,
        audiences: ['Employer']
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(Announcement.new(**params).save).to be_falsey
      end
    end

    context "with no content" do
      let(:params) {valid_params.except(:content)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:content].any?).to be_truthy
      end
    end

    context "with no start_date" do
      let(:params) {valid_params.except(:start_date)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:start_date].any?).to be_truthy
      end
    end

    context "with no end_date" do
      let(:params) {valid_params.except(:end_date)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:end_date].any?).to be_truthy
      end
    end

    context "with no audiences" do
      let(:params) {valid_params.except(:audiences)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:base].any?).to be_truthy
      end

      it "should get alert msg" do
        expect(Announcement.create(**params).errors[:base]).to include "Please select at least one Audience"
      end
    end

    context "end date old than today" do
      let(:params) do
        valid_params[:end_date] = TimeKeeper.date_of_record - 1.days
        valid_params
      end

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:base].any?).to be_truthy
      end

      it "should get alert msg" do
        expect(Announcement.create(**params).errors[:base]).to include "End Date should be later than today"
      end
    end

    context "end date before start date" do
      let(:params) do
        valid_params[:end_date] = TimeKeeper.date_of_record - 20.days
        valid_params
      end

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:base].any?).to be_truthy
      end

      it "should get alert msg" do
        expect(Announcement.create(**params).errors[:base]).to include "End Date should be later than Start date"
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:announcement) {Announcement.new(**params)}

      it "should save" do
        expect(announcement.save!).to be_truthy
      end
    end
  end

  describe "instance method" do
    it "audiences_for_display" do
      audiences = ['Employer', 'Employee']
      announcement = FactoryGirl.create(:announcement, audiences:audiences)
      expect(announcement.audiences_for_display).to eq audiences.join(',')
    end

    it "update_audiences" do
      audiences = ['Employer', 'Employee', '']
      announcement = FactoryGirl.create(:announcement, audiences:audiences)
      expect(announcement.audiences).to eq ['Employer', 'Employee']
    end
  end
end
