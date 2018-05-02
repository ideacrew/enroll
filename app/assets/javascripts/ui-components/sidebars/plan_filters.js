function filterMetalLevel(element) {
  console.log("Metal Level ",element.dataset.planMetalLevelFilter)
}

function filterPlanType(element) {
  console.log("Plan Type ",element.dataset.planCategoryFilter)
}

function filterPlanNetwork(element) {
  console.log("Plan Network ",element.dataset.planMetalNetworkFilter)
}

function filterPlanCarriers(element) {
  console.log("Plan Carriers ",element.value)
}

function filterHSAEligibility(element) {
  console.log("HSA Eligibility ",element.value)
}

function premuimFromAmount(element) {
  console.log("Premium From Amount ",element.value)
}

function premiumToAmount(element) {
  console.log("Premium To Amount ",element.value)
}

function deductibleFromAmount(element) {
  console.log("Deductible from Amount ",element.value)
}

function deductibleToAmount(element) {
  console.log("Deductible to Amount ",element.value)
}

function clearAll() {
  // Clears all inputs within #filter-sidebar only
  var inputs = document.querySelectorAll("#filter-sidebar input");
  
  for(var i = 0; i < inputs.length; i++) {
      inputs[i].checked = false;
      inputs[i].value = "";
  }
  
  var select = document.querySelectorAll("#filter-sidebar select");

}