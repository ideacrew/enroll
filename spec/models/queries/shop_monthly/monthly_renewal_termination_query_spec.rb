require "rails_helper"

describe "a monthly shop renewal termination query" do
  describe "given a renewing employer who has completed their open enrollment" do
    describe "with employees who have made the following plan selections:
       - employee A has purchased:
         - Health Coverage in the previous plan year (Enrollment 1)
         - One health enrollment (Enrollment 2)
       - employee B has purchased:
         - A health enrollment in the previous plan year (Enrollment 3)
         - One health enrollment (Enrollment 4)
         - Then a health waiver (Enrollment 5)
       - employee C has purchased:       
         - A health enrollment in the previous plan year (Enrollment 6)
         - One dental enrollment (Enrollment 7)
         - Then a health waiver (Enrollment 8)
       - employee D has purchased:       
         - A health enrollment in the previous plan year (Enrollment 9)
         - One dental enrollment (Enrollment 10)
         - Then a health waiver (Enrollment 11)
         - Then one health enrollment (Enrollment 12)
    " do

      it "includes enrollment 3"
      it "includes enrollment 6"
      it "does not include enrollment 1"
      it "does not include enrollment 9"
    end
  end
end
