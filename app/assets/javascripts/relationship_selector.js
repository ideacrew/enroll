$('#selected_relationship').change(function () {
    $.ajax({
        url: "/insured/family_relationships",
        method: "POST",
        dataType: 'script',
        data: {
            "kind": $("#selected_relationship option:selected").val() ,
            "predecessor_id":  $("#predecessor_id").val(),
            "successor_id": $("#successor_id").val()
        }
    })
});