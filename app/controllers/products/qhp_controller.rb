class Products::QhpController < ApplicationController

  def comparison
    @plans = Products::Qhp.all.sample(3)
  end

  def summary
    @plans = Products::Qhp.all.sample
  end
end
