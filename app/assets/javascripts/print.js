$(document).on('click', '#btnPrint', function(){
  var payment_text = document.getElementById("how_to_pay").innerHTML;
  printElement(document.getElementById("printArea"), true, payment_text);
  window.print();
});

function printElement(elem, append, delimiter) {
  var domClone = elem.cloneNode(true);

  var $printSection = document.getElementById("printSection");

  if (!$printSection) {
    var $printSection = document.createElement("div");
    $printSection.id = "printSection";
    document.body.appendChild($printSection);
  }

  if (append !== true) {
    $printSection.innerHTML = "";
  }

  else if (append === true) {
    $printSection.innerHTML = "";
    if (typeof(delimiter) === "string") {
      $printSection.innerHTML += delimiter;
    }
    else if (typeof(delimiter) === "object") {
      $printSection.appendChlid(delimiter);
    }
  }

  $printSection.appendChild(domClone);
}
