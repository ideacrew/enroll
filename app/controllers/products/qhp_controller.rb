class Products::QhpController < ApplicationController

  def comparison
    random_ids = Products::Qhp.pluck(:id).shuffle[0..2]
    @qhps = Products::Qhp.where(:_id.in => random_ids).to_a
  end

  def summary
    random_ids = Products::Qhp.pluck(:id).shuffle[1]
    @qhp = Products::Qhp.where(:_id => random_ids).to_a.first
  end
end
