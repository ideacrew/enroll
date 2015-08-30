function applyListeners(){

    $("input[name='dependent[us_citizen]']").change(function(){
        if ($(this).val()=='true') {
            $('#naturalized_citizen_container').show();
            $('#dependent_naturalized_citizen_true').attr('required');
            $('#dependent_naturalized_citizen_false').attr('required');
            $('#immigration_status_container').hide();
        }else{
            $('#dependent_naturalized_citizen_true').removeAttr('required');
            $('#dependent_naturalized_citizen_false').removeAttr('required');
            $('#naturalized_citizen_container').hide();
            $('#vlp_document_id_container').hide();
            $('#immigration_status_container').show();
        }
    });

    $("#naturalization_doc_type").change(function(){
        console.log($(this).val());

        if ($(this).val()=='Certificate of Citizenship') {
            $('#citizenship_cert_container').show();
            $('#naturalization_cert_container').hide();
        }
        else if ($(this).val()=='Naturalization Certificate') {
            $('#naturalization_cert_container').show();
            $('#citizenship_cert_container').hide();
        }
    });

    $("input[name='dependent[naturalized_citizen]']").change(function(){
		
        if ($(this).val()=='true') {
            $('#vlp_document_id_container').show();
        }else{
            $('#vlp_document_id_container').hide();
        }
    });

    $("input[name='person[us_citizen]']").change(function(){
        if ($(this).val()=='true') {
            $('#naturalized_citizen_container').show();
            $('#person_naturalized_citizen_true').attr('required');
            $('#person_naturalized_citizen_false').attr('required');
            $('#immigration_status_container').hide();
        }else{
            $('#person_naturalized_citizen_true').removeAttr('required');
            $('#person_naturalized_citizen_false').removeAttr('required');
            $('#naturalized_citizen_container').hide();
            $('#vlp_document_id_container').hide();
            $('#immigration_status_container').show();
        }
    });


    $("input[name='person[naturalized_citizen]']").change(function(){
        if ($(this).val()=='true') {
            $('#vlp_document_id_container').show();
        }else{
            $('#vlp_document_id_container').hide();
        }
    });

    $('#person_indian_tribe_member').change(function(){
        if($(this).is(':checked')) {
            $('#tribal_container').show();
        }
        else{
            $('#tribal_container').hide();
        }
    });

    $('#dependent_indian_tribe_member').change(function(){
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