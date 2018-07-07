function showCostDetails(cost,min,max) {
  document.getElementById('rpEstimatedMonthlyCost').append('$ '+cost);
  document.getElementById('rpMin').append('$ '+min);
  document.getElementById('rpMax').append('$ '+max);
}

function showEmployeeCostDetails(employees_cost) {
  var modal = document.getElementById('eeCostModal')
  modal.querySelectorAll('.row:not(.header)').forEach(function(element) {
    element.remove()
  });

  for (let employee in employees_cost) {
    estimate = employees_cost[employee];
    var newRow = document.importNode(modal.querySelector('.row.header'), true)
    newRow.querySelector('.col-xs-4.name').innerHTML = estimate.name;
    newRow.querySelector('.col-xs-2.dependents').innerHTML = estimate.dependent_count;
    newRow.querySelector('.col-xs-2.min').innerHTML = estimate.lowest_cost_estimate;
    newRow.querySelector('.col-xs-2.reference').innerHTML = estimate.reference_estimate;
    newRow.querySelector('.col-xs-2.max').innerHTML = estimate.highest_cost_estimate;
    modal.querySelector('.modal-body').appendChild(newRow);
  }
}


function calculateEmployeeCosts(productOptionKind,referencePlanID)  {
  $.ajax({
    type: "GET",
    data:{ sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID } } },
    url: "calculate_employee_cost_details",
    success: function (d) {
      showEmployeeCostDetails(d);
    }
  });
}

function calculateEmployerContributions(productOptionKind,referencePlanID)  {
  $.ajax({
    type: "GET",
    data:{ sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID } } },
    url: "calculate_employer_contributions",
    success: function (d) {
      var eeMin = parseFloat(d["estimated_enrollee_minimum"]).toFixed(2);
      var eeCost = parseFloat(d["estimated_total_cost"]).toFixed(2);
      var eeMax = parseFloat(d["estimated_enrollee_maximum"]).toFixed(2);
      showCostDetails(eeCost,eeMin,eeMax)
    }
  });
}


module.exports = {
  calculateEmployerContributions : calculateEmployerContributions,
  calculateEmployeeCosts : calculateEmployeeCosts
};
