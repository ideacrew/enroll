//Clear filter selections on page refresh
window.addEventListener('load', function() {
  clearAll();
})

// Stores values to be processed on function filterResults
var selectedMetalLevels = [];
var selectedPlanTypes = [];
var selectedPlanNetworks = [];
var premiumFromAmountValue = new String;
var premiumToAmountValue = new String;
var deductibleFromAmountValue = new String;
var deductibleToAmountValue = new String;

function filterMetalLevel(element) {
  if (element.checked) {
    var metalLevel = element.dataset.planMetalLevel
    selectedMetalLevels.push(metalLevel)
  }
  if (!element.checked) {
    var metalLevel = element.dataset.planMetalLevel
    index = selectedMetalLevels.indexOf(metalLevel)
    removeItems(selectedMetalLevels,index)
  }
}

function filterPlanType(element) {
  if (element.checked) {
    var planType = element.dataset.planType
    selectedPlanTypes.push(planType)
  }
  if (!element.checked) {
    var planType = element.dataset.planType
    index = selectedPlanTypes.indexOf(planType)
    removeItems(selectedPlanTypes,index)
  }
}

function filterPlanNetwork(element) {
  if (element.checked) {
    var planNetwork = element.dataset.planNetwork
    selectedPlanNetworks.push(planNetwork)
  }
  if (!element.checked) {
    var planNetwork = element.dataset.planNetwork
    index = selectedPlanNetworks.indexOf(planNetwork)
    removeItems(selectedPlanNetworks,index)
  }
}

function filterPlanCarriers(element) {
  console.log("Plan Carriers ",element.value)
}

function filterHSAEligibility(element) {
  console.log("HSA Eligibility ",element.value)
}

function premuimFromAmount(element) {
  premiumFromAmountValue = element.value
}

function premiumToAmount(element) {
  premiumToAmountValue = element.value
}

function deductibleFromAmount(element) {
  deductibleFromAmountValue = element.value
}

function deductibleToAmount(element) {
  deductibleToAmountValue = element.value
}

function clearAll() {
  // Clears all checkboxes within #filter-sidebar only
  var inputs = document.querySelectorAll("#filter-sidebar input");
  
  for(var i = 0; i < inputs.length; i++) {
      inputs[i].checked = false;
      inputs[i].value = "";
  }
  // Clear stored values
  selectedMetalLevels = [];
  selectedPlanTypes = [];
  selectedPlanNetworks = [];
  premiumFromAmountValue = "";
  premiumToAmountValue = "";
  deductibleFromAmountValue = "";
  deductibleToAmountValue = "";
  
  var select = document.querySelectorAll("#filter-sidebar select");

}

// Gets the filtered Results
function filterResults() {
  console.log("Selected Metal Levels ", selectedMetalLevels)
  console.log("Selected Plan Types ", selectedPlanTypes)
  console.log("Selected Networks ", selectedPlanNetworks)
  console.log("Premium From amount ", premiumFromAmountValue)
  console.log("Premium To amount ", premiumToAmountValue)
  console.log("Deductible From amount ", deductibleFromAmountValue)
  console.log("Deductible To amount ", deductibleToAmountValue)
}

// Removes an item from array
function removeItems(arr, index) {
  arr.splice(index,1)
}