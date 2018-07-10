function showCostDetails(cost,min,max) {
  document.getElementById('rpEstimatedMonthlyCost').append('$ '+cost);
  document.getElementById('rpMin').append('$ '+min);
  document.getElementById('rpMax').append('$ '+max);
}

function showEmployeeCostDetails(employees_cost) {
  var table = document.getElementById('eeTableBody');
  table.querySelectorAll('tr').forEach(function(element) {
    element.remove()
  });
  //modal = document.getElementById('modalInformation')
  //row = document.createElement('col-xs-12')
  //row.innerHTML = `Plan Offerings - <br/>Employer Lowest/Reference/Highest -`
  //modal.appendChild(row)

  for (var employee in employees_cost) {
    var tr = document.createElement('tr')
    estimate = employees_cost[employee];
    tr.innerHTML =
    `
      <td class="text-center">${estimate.name}</td>
      <td class="text-center">${estimate.dependent_count}</td>
      <td class="text-center">$ ${estimate.lowest_cost_estimate}</td>
      <td class="text-center">$ ${estimate.reference_estimate}</td>
      <td class="text-center">$ ${estimate.highest_cost_estimate}</td>
    `
    table.appendChild(tr)
  }
}


function calculateEmployeeCosts(productOptionKind,referencePlanID, sponsoredBenefitId)  {
  var thing = $("input[name^='benefit_package['").serializeArray();
  var submitData = {};
  for (item in thing) {
    submitData[thing[item].name] = thing[item].value;
  }
  // We have to append this afterwards because somehow, somewhere, there is an empty field corresponding
  // to product package kind.
  submitData['benefit_package'] = {
    sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID, id: sponsoredBenefitId } }
  };
  $.ajax({
    type: "GET",
    data: submitData,
    url: "calculate_employee_cost_details",
    success: function (d) {
      showEmployeeCostDetails(d);
    }
  });
}

function calculateEmployerContributions(productOptionKind,referencePlanID, sponsoredBenefitId)  {
  var thing = $("input[name^='benefit_package['").serializeArray();
  var submitData = { };
  for (item in thing) {
    submitData[thing[item].name] = thing[item].value;
  }
  // We have to append this afterwards because somehow, somewhere, there is an empty field corresponding
  // to product package kind.
  submitData['benefit_package'] = {
    sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID, id: sponsoredBenefitId } }
  };
  $.ajax({
    type: "GET",
    data: submitData,
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
