function calculateEmployerContributions(productOptionKind,referencePlanID)  {
    $.ajax({
      type: "GET",
      data:{product_package_kind: productOptionKind,reference_plan_id: referencePlanID},
      url: "calculate_employer_contributions",
      success: function (d) {
        var eeMin = parseFloat(d["estimated_enrollee_minium"]).toFixed(2);
        var eeCost = parseFloat(d["estimated_total_cost"]).toFixed(2);
        var eeMax = parseFloat(d["estimated_enrollee_maximum"]).toFixed(2);
        showCostDetails(eeCost,eeMin,eeMax)
      }
    });
  }


module.exports = { 
  calculateEmployerContributions : calculateEmployerContributions
};