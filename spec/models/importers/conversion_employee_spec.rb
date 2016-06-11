require 'rails_helper'

RSpec.describe Importers::ConversionEmployee, type: :model do

  describe "syntax validation" do
    context "unable to recognize file as CSV or Excel" do
    end

    context "import file is empty" do
    end

    context "file has content" do
      context "and the first row is a header row" do
      end

      context "and the first row is a data row" do
        context "and row has incorrect number of cells" do
        end

        context "and row has correct number of cells" do
          context "and one or more required fields are nil" do
          end

          context "and all required fields are present" do
            context "and one or more required fields fail to parse" do
              it "adds an error to the model"
              it "adds an error to the model's base array"
            end

            context "and all required fields are correctly formatted" do
              context "and one or more optional fields fail to parse" do
                it "adds an error to the model"
              end

              context "and all optional fields are correctly formatted or nil" do            
              end
            end
          end
        end

      end
    end
  end

  describe "functional validation at the record level" do
    context "employer fein is not found for this employee" do
    end

    context "employer fein is found for this employee" do
    end
  end


  describe "functional validation at the imported set level" do
    context "file contains more than one record for the same employee" do
    end
  end


  describe "persisting the imported set level" do
    context "and at least one record has an error" do
    end

    context "and at least one record has a base level error" do
    end

    context "and there are no errors" do
    end
  end

  
end
