//Clear filter selections on page refresh
window.addEventListener('load', function() {
  clearAll();
})

// Stores values to be processed on function filterResults
var filterParams = {
  selectedMetalLevels: new Array,
  selectedPlanTypes: new Array,
  selectedPlanNetworks: new Array,
  selectedCarrier: new String,
  selectedHSA: new String,
  premiumFromAmountValue: new String,
  premiumToAmountValue: new String,
  deductibleFromAmountValue: new String,
  deductibleToAmountValue: new String
}

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
  filterParams.selectedCarrier = element.value
}

function filterHSAEligibility(element) {
  filterParams.selectedHSA = element.value
}

function premuimFromAmount(element) {
  filterParams.premiumFromAmountValue = element.value
}

function premiumToAmount(element) {
  filterParams.premiumToAmountValue = element.value
}

function deductibleFromAmount(element) {
  filterParams.deductibleFromAmountValue = element.value
}

function deductibleToAmount(element) {
  filterParams.deductibleToAmountValue = element.value
}
// Passes values from inputs and passes to array
function processValues(element) {
  if (element.checked) {
    var dataType = element.dataset.category;
 
    if (dataType == "planMetalLevel") {
      filterParams.selectedMetalLevels.push(element.dataset.planMetalLevel)
    }
    if (dataType == "planType") {
      filterParams.selectedPlanTypes.push(element.dataset.planType)
    }
    if (dataType == "planNetwork") {
      filterParams.selectedPlanNetworks.push(element.dataset.planNetwork)
    }
  }
  if (!element.checked) {
    var dataType = element.dataset.category;
    
    if (dataType == "planMetalLevel") {
      index = filterParams.selectedMetalLevels.indexOf(element.dataset.planMetalLevel)
      removeItems(filterParams.selectedMetalLevels,index)
    }
    if (dataType == "planType") {
      index = filterParams.selectedPlanTypes.indexOf(element.dataset.planType)
      removeItems(filterParams.selectedPlanTypes,index)
    }
    if (dataType == "planNetwork") {
      index = filterParams.selectedPlanNetworks.indexOf(element.dataset.planNetwork)
      removeItems(filterParams.selectedPlanNetworks,index)
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
  filterParams.selectedMetalLevels = [];
  filterParams.selectedPlanTypes = [];
  filterParams.selectedPlanNetworks = [];
  filterParams.selectedCarrier = "";
  filterParams.selectedHSA = "";
  filterParams.premiumFromAmountValue = "";
  filterParams.premiumToAmountValue = "";
  filterParams.deductibleFromAmountValue = "";
  filterParams.deductibleToAmountValue = "";
}

// Gets the filtered Results
function filterResults() {
  console.log("Selected Metal Levels ", filterParams.selectedMetalLevels)
  console.log("Selected Plan Types ", filterParams.selectedPlanTypes)
  console.log("Selected Networks ", filterParams.selectedPlanNetworks)
  console.log("Selected Carrier ", filterParams.selectedCarrier)
  console.log("Selected HSA ", filterParams.selectedHSA)
  console.log("Premium From amount ", filterParams.premiumFromAmountValue)
  console.log("Premium To amount ", filterParams.premiumToAmountValue)
  console.log("Deductible From amount ", filterParams.deductibleFromAmountValue)
  console.log("Deductible To amount ", filterParams.deductibleToAmountValue)
}

// Removes an item from array
function removeItems(arr, index) {
  arr.splice(index,1)
}