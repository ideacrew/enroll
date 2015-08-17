function applyListeners(){

    $("input[name='citizen_status']").change(function(){
        if ($(this).val()=='yes') {
            $('#naturalized_citizen_container').show();
            $('#immigration_status_container').hide();
        }else{
            $('#naturalized_citizen_container').hide();
            $('#vlp_document_id_container').hide();
            $('#immigration_status_container').show();
        }
    });


    $("input[name='naturalized_citizen']").change(function(){
        if ($(this).val()=='yes') {
            $('#vlp_document_id_container').show();
        }else{
            $('#vlp_document_id_container').hide();
        }
    });

    $('#american_indian_tribe').change(function(){
        if($(this).is(':checked')) {
            $('#tribal_container').show();
        }
        else{
            $('#tribal_container').hide();
        }
    });
}



$(function () {
    applyListeners();
});