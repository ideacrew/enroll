$(document).ready(function () {
    $(document).on("change", ".selected_relationship", function () {
        // console.log($(this).val());
        // console.log($(this).data("predecessor"));
        // console.log($(this).data("successor"));
        $.ajax({
            url: "/insured/family_relationships",
            method: "POST",
            dataType: 'script',
            data: {
                "kind": $(this).val(),
                "predecessor_id": $(this).data("predecessor"),
                "successor_id": $(this).data("successor")
            }
        })
    });
});