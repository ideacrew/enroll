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
  selectedOSSE: new String,
  premiumFromAmountValue: new String,
  premiumToAmountValue: new String,
  deductibleFromAmountValue: new String,
  deductibleToAmountValue: new String
}

document.addEventListener('DOMContentLoaded', function() {
  // Select all elements with the class 'plan-type-selection-filter'
  var planTypeInputs = document.querySelectorAll('.plan-type-selection-filter');

  // Add a click event listener to each checkbox
  planTypeInputs.forEach(function(planTypeInput) {
    planTypeInput.addEventListener('click', function() {
      filterPlanType(this);
    });
  });

  // Select all elements with the class 'plan-type-selection-filter'
  var metalLevelInputs = document.querySelectorAll('.plan-metal-level-selection-filter');

  // Add a click event listener to each checkbox
  metalLevelInputs.forEach(function(metalLevelInput) {
    metalLevelInput.addEventListener('click', function() {
      filterMetalLevel(this);
    });
  });

  // Select all elements with the class 'plan-type-selection-filter'
  var metalNetworkInputs = document.querySelectorAll('.plan-metal-network-selection-filter');

  // Add a click event listener to each checkbox
  metalNetworkInputs.forEach(function(metalNetworkInput) {
    metalNetworkInput.addEventListener('click', function() {
      filterMetalLevel(this);
    });
  });

  var carrierSelect = document.querySelector('.plan-carrier-selection-filter');
  if (carrierSelect) {
    carrierSelect.addEventListener('change', function() {
      filterPlanCarriers(this);
    });
  }

  var hsaSelectionFilter = document.querySelector('.plan-hsa-eligibility-selection-filter');
  if (hsaSelectionFilter) {
    hsaSelectionFilter.addEventListener('change', function() {
      filterHSAEligibility(this);
    });
  }
});

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

function filterOSSEEligibility(element) {
  filterParams.selectedOSSE = element.value
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
  } else if (!element.checked) {
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
  var inputs = document.querySelectorAll("#filter-sidebar .filter-input-block input");
  // Clears slections from view
  // clearSelections()

  for(var i = 0; i < inputs.length; i++) {
      inputs[i].checked = false;
      inputs[i].value = "";
  }
  // Load only on plan_shopping page
  if (window.location.pathname.split('/')[2] == "plan_shoppings") {
    // Select options -- WISH LIST GET RID OF SELECTRIC TO REMOVE JQUERY RELIANCE --
    $("#filter-sidebar select.plan-carrier-selection-filter").prop('selectedIndex', 0).selectric('refresh');
    $("#filter-sidebar select.plan-hsa-eligibility-selection-filter").prop('selectedIndex', 0).selectric('refresh');
    $("#filter-sidebar select.plan-osse-eligibility-selection-filter").prop('selectedIndex', 0).selectric('refresh');
  }
  
  
  // Clear stored values
  filterParams.selectedMetalLevels = [];
  filterParams.selectedPlanTypes = [];
  filterParams.selectedPlanNetworks = [];
  filterParams.selectedCarrier = "";
  filterParams.selectedHSA = "";
  filterParams.selectedOSSE = "";
  filterParams.premiumFromAmountValue = "";
  filterParams.premiumToAmountValue = "";
  filterParams.deductibleFromAmountValue = "";
  filterParams.deductibleToAmountValue = "";
}

// Gets the filtered Results
function filterResults() {
  filterResultsSelections(filterParams)
}

// Removes an item from array
function removeItems(arr, index) {
  arr.splice(index,1)
}