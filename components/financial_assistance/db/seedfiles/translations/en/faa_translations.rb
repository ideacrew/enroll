# frozen_string_literal: true

# Assistance Translations

module FaaTranslations
  ASSISTANCE_TRANSLATIONS = {
    "en.faa.start_new_application" => 'Start New Application',
    "en.faa.cancel" => 'Cancel',
    "en.faa.curam_lookup" => "It looks like you've already completed an application for Medicaid and cost savings on DC Health Link. Please call DC Health Link at (855) 532-5465 to make updates to that application. If you keep going, we'll check to see if you qualify to enroll in a private health insurance plan on DC Health Link, but won't be able to tell you if you qualify for Medicaid or cost savings.",
    "en.faa.acdes_lookup" => "It looks like you're already covered by Medicaid. Please call DC Health Link at (855) 532-5465 to make updates to your case. If you keep going, we'll check to see if you qualify to enroll in a private health insurance plan on DC Health Link, but won't be able to tell you if you qualify for Medicaid or cost savings.",

    "en.faa.other_ques.disability_question" => "Does this person have a disability? *",
    "en.faa.review_eligibility_header" => "Your Application for Premium Reductions",
    'en.faa.other_ques.is_student' => 'Is this person a student? *',
    "en.faa.medicaid_question" => "Do you want us to submit this application to the <state-abbreviation-placeholder> Department of Human Services (DHS) to do a full review of your application for Medicaid eligibility?",
    'en.faa.edit.delete_applicant' => 'Are you sure you want to remove this applicant?',
    'en.faa.edit.remove_warning' => 'This cannot be undone.',
    'en.faa.incomes.job_income_note' => "Note: For job income this person currently receives, do not enter an end date into the ‘To’ field. Only enter an end date if the job income ended.",
    'en.faa.cost_savings.start_new_application' => 'Are you sure you want to start a brand new application?',
  }.freeze

  ELIGIBILITY_TRANSLATIONS = {
    "en.faa.eligibility_results" => "Eligibility Results",
    "en.faa.we_have_your_results" => "We have your results",
    "en.faa.medicaid" => "Medicaid",
    "en.faa.eligible_for_medicaid" => "These people <span>appear to be eligible</span> for Medicaid",
    "en.faa.dhs_decision" => "<span>PLEASE NOTE: The DC Department of Human Services (DHS) will make a final decision on whether those listed qualify for <span class='run-glossary'>Medicaid</span>.</span>",
    "en.faa.dhs_contact" => "They will send you a letter, and may ask you to provide documents. If you haven’t heard from DHS within 45 days, you may want to ask for an update by calling us at (855) 532-5465.",
    "en.faa.premium_reductions_1" => "These people are <span>eligible for monthly premium reductions of",
    "en.faa.premium_reductions_2" => "per month.</span> This means they won't have to pay full price for health insurance.",
    "en.faa.qualify_for_lower_costs_1" => "They also qualify for lower out-of-pocket costs - a benefit that lowers other costs like the annual deductible and copayments. ",
    "en.faa.silver_plan_checkmark" => "This benefit is only available if these people select a silver plan. Look for this check mark ",
    "en.faa.qualify_for_lower_costs_2" => " on plans that have this benefit.",
    "en.faa.does_not_qualify" => "Does not qualify",
    "en.faa.likely_does_not_qualify" => "These people <span> likely don't qualify for <span class='run-glossary'>Medicaid</span>, </span> and don't qualify for private health insurance through DC Health Link:",
    "en.faa.private_health_insurance" => "Private health insurance",
    "en.faa.qualified_to_enroll" => "These people <span> qualify to enroll </span> in a private health insurance plan:",
    "en.faa.do_not_agree" => "If you do not agree with this determination, you have the right to appeal. <a href=''>Find out more about the appeal process</a> or <a href=''>get assistance</a> by contacting us directly.",
    "en.faa.your_application_reference" => "Your application reference number is ",
    "en.faa.next_step_without_aggregate" => "<b>NEXT STEP:</b> Pick a health insurance plan.",
    "en.faa.next_step_with_aggregate_1" => "<b>NEXT STEP:</b><ul><li><b>If you’re already enrolled in DC Health Link’s Individual & Family plan</b>, we’ve automatically changed your premium. You don’t have to do anything else.</li>",
    "en.faa.next_step_with_aggregate_2" => "<br><li><b>If you’re not enrolled or need to make changes to your plan</b>, select CONTINUE to pick a health insurance plan or change who is covered by your plan.</li></ul>"
  }.freeze
end
