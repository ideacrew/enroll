# Script to qle effective on kind. retiring exact_date kind to  date_of_event.

QualifyingLifeEventKind.where(:effective_on_kinds.in=> ['exact_date']).each do |qle|
  qle.update_attributes(effective_on_kinds: qle.effective_on_kinds.map{|kind| kind == "exact_date" ? "date_of_event": kind})
end