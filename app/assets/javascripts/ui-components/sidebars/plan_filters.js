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
  processValues(element)
}

function filterPlanType(element) {
  processValues(element)
}

function filterPlanNetwork(element) {
  processValues(element)
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
// Passes values from inputs and passes to array
function processValues(element) {
  if (element.checked) {
    var dataType = element.dataset.category;
 
    if (dataType == "planMetalLevel") {
      selectedMetalLevels.push(element.dataset.planMetalLevel)
    }
    if (dataType == "planType") {
      selectedPlanTypes.push(element.dataset.planType)
    }
    if (dataType == "planNetwork") {
      selectedPlanNetworks.push(element.dataset.planNetwork)
    }
  }
  if (!element.checked) {
    var dataType = element.dataset.category;
    
    if (dataType == "planMetalLevel") {
      index = selectedMetalLevels.indexOf(element.dataset.planMetalLevel)
      removeItems(selectedMetalLevels,index)
    }
    if (dataType == "planType") {
      index = selectedPlanTypes.indexOf(element.dataset.planType)
      removeItems(selectedPlanTypes,index)
    }
    if (dataType == "planNetwork") {
      index = selectedPlanNetworks.indexOf(element.dataset.planNetwork)
      removeItems(selectedPlanNetworks,index)
    }
  }
}

function clearAll() {
  // Clears all checkboxes within #filter-sidebar only
  var inputs = document.querySelectorAll("#filter-sidebar input");
  
  for(var i = 0; i < inputs.length; i++) {
      inputs[i].checked = false;
      inputs[i].value = "";
  }
  // Select options -- WISH LIST GET RID OF SELECTRIC TO REMOVE JQUERY RELIANCE --
  $("#filter-sidebar select.plan-carrier-selection-filter").prop('selectedIndex', 0).selectric('refresh');
  $("#filter-sidebar select.plan-hsa-eligibility-selection-filter").prop('selectedIndex', 0).selectric('refresh');
  
  // Clear stored values
  selectedMetalLevels = [];
  selectedPlanTypes = [];
  selectedPlanNetworks = [];
  premiumFromAmountValue = "";
  premiumToAmountValue = "";
  deductibleFromAmountValue = "";
  deductibleToAmountValue = "";
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