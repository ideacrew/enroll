//= require vendor/jquery.delayedChange
//= require dataTables/jszip/jszip

//= require dataTables/jquery.dataTables
//= require dataTables/dataTables.bootstrap

//= require dataTables/buttons/dataTables.buttons
//= require dataTables/buttons/buttons.bootstrap
//= require dataTables/buttons/buttons.colVis
//= require dataTables/buttons/buttons.html5
//= require dataTables/buttons/buttons.print
//= require dataTables/colreorder/dataTables.colReorder
//= require dataTables/responsive/dataTables.responsive
//= require dataTables/responsive/responsive.bootstrap

//= require effective_datatables/bulk_actions
//= require effective_datatables/responsive
//= require effective_datatables/scopes
//= require effective_datatables/charts

//= require effective_datatables/initialize

/*
$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'col-sm-4'l><'col-sm-8'B>><'row'<'col-sm-4'><'col-sm-8'f>><'row'<'col-sm-12'tr>><'row'<'col-sm-6'i><'col-sm-6'p>>"
});
*/

var bs4 = document.documentElement.dataset.bs4;
if (bs4) {
  $.extend( $.fn.dataTable.defaults, {
    'dom': "<'d-flex align-items-center w-100 justify-content-between mb-4'" +
          "Bf" +
          ">" +
          "<'d-flex align-items-center w-100 '" +
          "<'col-sm-12 col-md-12'>" +
          ">" +
          "<'d-flex align-items-center w-100 '" +
          "<'col-sm-12 col-md-12 px-0'tr>"+
          ">" +
          "<'d-flex justify-content-between align-items-center w-100'" +
          "il" +
          ">" +
          "<'d-flex align-items-center justify-content-center w-100 my-4'" +
          "p" +
          ">"
  });
} else {
  $.extend( $.fn.dataTable.defaults, {
    'dom': "<'row'" +
            "<'col-sm-7 col-md-7'B><'col-sm-5 col-md-5'f>" +
          ">" +
          "<'row'" +
            "<'col-sm-12 col-md-12'>" +
          ">" +
          "<'row'" +
            "<'col-sm-12 col-md-12'tr>"+
          ">" +
          "<'row'" +
            "<'col-sm-11 col-md-11'i><'col-sm-1 col-md-1'l>" +
          ">" +
          "<'row'" +
            "<'col-sm-12 col-md-12'p>" +
          ">"
  });
}
