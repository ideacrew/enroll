function check_dob_change_implication(person_id, new_dob) {
  $.ajax({
      type: "GET",
      data:{person_id: person_id, new_dob: new_dob},
      url: "/hbx_profiles/verify_dob_change"
    }); 
}
