class Products::QhpController < ApplicationController

  def comparison
    @qhps = Products::Qhp.all.sample(3)
  end

  def summary
    @qhp = Products::Qhp.all.sample
  end
end
