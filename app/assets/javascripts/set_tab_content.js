function set_tab_content(partial) {
  console.log('set_tab_content');
  $('.flash').remove();
  $('#inbox > .col-xs-12').html(partial);
}

function set_active_ontab(tab_id) {
  $(tab_id).siblings().each(function(){
    $(this).removeClass('active');
  });
  $(tab_id).addClass('active');
}

function set_broker_agency_content(partial) {
  $('#broker_agency_panel > .col-xs-12').html(partial);
}


function setTabContent(partial) {
  console.log('setTabContent');
  $('.flash').remove();
  $('#myTabContent').html(partial);
}
