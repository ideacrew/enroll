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
    var newRow = document.importNode(modal.querySelector('.row.header'), true)
    newRow.querySelector('.col-xs-4.name').innerHTML = employee
    newRow.querySelector('.col-xs-2.dependents').innerHTML = employees_cost[employee].dependents
    newRow.querySelector('.col-xs-2.min').innerHTML = employees_cost[employee].costs[0]
    newRow.querySelector('.col-xs-2.reference').innerHTML = employees_cost[employee].costs[1]
    newRow.querySelector('.col-xs-2.max').innerHTML = employees_cost[employee].costs[2]
    modal.querySelector('.modal-body').appendChild(newRow);
  }
}


function calculateEmployeeCosts(productOptionKind,referencePlanID)  {
  $.ajax({
    type: "GET",
    data:{product_package_kind: productOptionKind,reference_plan_id: referencePlanID},
    url: "calculate_employee_cost_details",
    success: function (d) {
      var employee_structure = { dependents: 0, costs: [] }
      var employees_cost = {}
      for (let employees of d) {
        for (let employee of employees) {
          var name = `${employee.members[0].census_member.first_name} ${employee.members[0].census_member.last_name}`
          if (!employees_cost[name])
            employees_cost[name] = employee_structure;
          employees_cost[name].costs.push(employee.group_enrollment.product_cost_total)
          employees_cost[name].dependents = employee.members.length - 1
        }
      }
      showEmployeeCostDetails(employees_cost)
    }
  });
}

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
  calculateEmployerContributions : calculateEmployerContributions,
  calculateEmployeeCosts : calculateEmployeeCosts
};
