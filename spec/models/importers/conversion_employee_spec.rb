require 'rails_helper'

RSpec.describe Importers::ConversionEmployee, type: :model do
  let (:required_fields)  { [] }
  let (:optional_fields)  { [] }

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
          it "adds a 'invalid record format' error to the instance"
          it "adds the error to the instance's error[:base] array"
        end

        context "and row has correct number of cells" do
          context "and a required field is nil" do
              it "adds a 'nil required field' error to the instance"
              it "adds the error to the instance's error[:base] array"
          end

          context "and all required fields have values" do
            context "and a required field fails to parse" do
              it "adds a 'required field parse failure' error to the instance"
              it "adds the error to the instance's error[:base] array"
            end

            context "and all required fields successfully parse" do
              context "and an optional field fails to parse" do
                it "adds a 'optional field parse failure' error to the instance"
                it "sets the optional field value to nil"
              end

              context "and all fields successfully parse" do
                it "the record instance should be valid"
              end
            end
          end
        end

      end
    end
  end

  describe "functional validation at the record level" do
    context "an employee without dependents is added" do
      context "and the sponsor employer is not found" do
      end

      context "and the sponsor employer is found" do
      end
    end

    describe "an employee without dependents is updated" do
      context "and the sponsor employer is not found" do
        it "adds a 'employer not found' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end

      context "and the sponsor employer is found" do
        context "and a pre-existing employee record is not found" do
          it "adds the employee record"
        end

        context "and a pre-existing employee record is found" do

          context "and the employee's name is changed" do
            context "and the employee's record has not changed since import" do
              it "should change the employee name"
            end

            context "and the employee's record has changed since import" do
              it "adds an 'update inconsistancy: employee record changed' error to the instance"
              it "adds the error to the instance's error[:base] array"
            end
          end

          context "and the employee's gender and dob are changed" do
            context "and the employee's record has not changed since import" do
              it "should change the employee gender and dob"
            end

            context "and the employee's record has changed since import" do
              it "adds an 'update inconsistancy: employee record changed' error to the instance"
              it "adds the error to the instance's error[:base] array"
            end
          end

          context "and the employee's address is changed" do
            context "and the employee's address record has not changed since import" do
              it "should change the employee address"
            end

            context "and the employee's address record has changed since import" do
              it "adds an 'update inconsistancy: employee address record changed' error to the instance"
              it "adds the error to the instance's error[:base] array"
            end
          end

          context "and the employee's plan HIOS ID is changed" do
            context "and the employee's enrollment is not auto-renewed" do
              it "should change the employee enrollment plan HIOS ID"
            end

            context "and the employee's enrollment is auto-renewed" do
              context "and the employee has not changed renewal enrollment" do
                it "should change the employee enrollment plan HIOS ID"
                it "should change the employee auto-renewed enrollment to mapped plan HIOS ID"
              end

              context "and the employee has changed renewal enrollment" do
                it "adds an 'update inconsistancy: employee enrollment record changed' error to the instance"
                it "adds the error to the instance's error[:base] array"
              end
            end
          end

          context "and a dependent is added" do
            it "should add the dependent"
          end

        end
      end
    end

    describe "an employee with dependents is added" do
      it "should add the employee and dependents"
    end

    describe "an employee with dependents is updated" do
      context "and a dependent is deleted" do
        it "adds an 'update not supported: dependent delete' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end

  end


  describe "functional validation at the imported set level" do
    context "" do
    end

    context "file contains more than one record for the same employee" do
    end
  end


  describe "persisting the imported set level" do
    context "and at least one record has a [:base] level error" do
      context "and the persistance flag is set to 'atomicity' (all or nothing)" do
        it "should not persist the set"
      end

      context "and the persistance flag is set to 'permissive'" do
        it "should persist all records that do not have a [:base] level error"
      end
    end

    context "and at least one record has only non-[:base] level errors" do
      context "and the persistance flag is set to 'atomicity' (all or nothing)" do
        it "should not persist the set"
      end
      
      context "and the persistance flag is set to 'permissive'" do
        it "should persist all records that don't have a [:base] error"
      end
    end

    context "and there are no errors" do
        it "should persist all records"
    end
  end


end
