require "rails_helper"

describe "a monthly shop enrollment query" do
  describe "given an employer who has completed their first open enrollment" do
    describe "with employees who have made the following plan selections:
       - employee A has purchased:
         - One health enrollment (Enrollment 1)
       - employee B has purchased:
         - One health enrollment (Enrollment 2)
         - Then a health waiver (Enrollment 3)
       - employee C has purchased:       
         - One health enrollment (Enrollment 4)
         - One dental enrollment (Enrollment 5)
         - Then a health waiver (Enrollment 6)
         - Then another health enrollment (Enrollment 7)
    " do

      it "includes enrollment 1"
      it "does not include enrollment 2"
      it "does not include enrollment 3"
      it "does not include enrollment 4"
      it "includes enrollment 5"
      it "does not include enrollment 6"
      it "includes enrollment 7"
    end
  end

  describe "given a renewing employer who has completed their open enrollment" do
    describe "with employees who have made the following plan selections:
       - employee A has purchased:
         - Health Coverage in the previous plan year (Enrollment 1)
         - One health enrollment (Enrollment 2)
       - employee B has purchased:
         - One health enrollment (Enrollment 3)
         - Then a health waiver (Enrollment 4)
       - employee C has purchased:       
         - One health enrollment (Enrollment 5)
         - One dental enrollment (Enrollment 6)
         - Then a health waiver (Enrollment 7)
         - Then another health enrollment (Enrollment 8)
    " do

      it "does not include enrollment 1"
      it "includes enrollment 2"
      it "does not include enrollment 3"
      it "does not include enrollment 4"
      it "does not include enrollment 5"
      it "does not include enrollment 7"
      it "includes enrollment 6"
      it "includes enrollment 8"
    end
  end
end
