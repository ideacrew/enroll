require "rails_helper"

describe Import::ConversionEmployeeUpdate do
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
            it "adds an 'update inconsistancy: employee record changed' error"
            it "adds the error to the instance's error[:base] array"
          end
        end

        context "and the employee's address is changed" do
          context "and the employee's address record has not changed since import" do
            it "should change the employee address"
          end

          context "and the employee's address record has changed since import" do
            it "adds an 'update inconsistancy: employee address record changed' error"
            it "adds the error to the instance's error[:base] array"
          end
        end

        context "and a dependent is added" do
          context "and the dependent date of birth is in the future" do
            it "adds an 'dependent date of birth in the future not allowed' error"
            it "adds the error to the instance's error[:base] array"
          end

          context "and the dependent is a spouse" do
            it "should add the dependent spouse"
          end

          context "and the dependent is a child" do
            context "and the child is 26 years of age or older on the renewal effective date" do
              it "should not add the child dependent"
              it "adds a 'over-age dependent add failure' error"
            end

            context "and the child is under age 26 on the renewal effective date" do
              it "should add the dependent"
            end
          end

          context "and the dependent is any relationship besides spouse, child or domestic partner" do
            it "should not add the dependent"
            it "adds a 'dependent add failure: invalid relationship' error to the instance"
          end

        end

      end
    end
  end

  describe "an employee with dependents is updated" do
    context "and a dependent is added" do
      context "and the dependent is found in employee record" do
        it "adds an 'update inconsistancy: duplicate employee dependent not allowed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end

      context "and the dependent is not found in employee record" do
        context "and the dependent is a spouse" do
          it "should add the spouse dependent"
        end

        context "and the dependent is a domestic partner" do
          it "should add the domestic partner dependent"
        end

        context "and the dependent is a child" do
          context "and the child is 26 years of age or older on the renewal effective date" do
            context "and the child is disabled" do
              it "should add the child dependent"
            end

            context "and the child is not disabled" do
              it "should not add the child dependent"
              it "adds a 'dependent add failure: over-age child' error to the instance"
            end
          end

          context "and the child is under age 26 on the renewal effective date" do
            it "should add the child dependent"
          end
        end

      end
    end

    context "and a dependent is deleted" do
      it "adds an 'update not supported: dependent delete' error to the instance"
      it "adds the error to the instance's error[:base] array"
    end

    context "and the employee dependent's name and ssn is changed" do
      context "and the employee dependent's record has not changed since import" do
        it "should change the employee dependent name and ssn"
      end

      context "and the employee dependent's record has changed since import" do
        it "adds an 'update inconsistancy: employee dependent record changed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end

    context "and the employee dependent's gender and dob are changed" do
      context "and the employee dependent's record has not changed since import" do
        it "should change the employee dependent gender and dob"
      end

      context "and the employee dependent's record has changed since import" do
        it "adds an 'update inconsistancy: employee dependent record changed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end

    context "and the employee dependent's address is changed" do
      context "and the employee dependent's record has not changed since import" do
        it "should change the employee dependent address"
        it "should not change the employee address"
      end

      context "and the employee dependent's record has changed since import" do
        it "adds an 'update inconsistancy: employee dependent record changed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end
  end
end
