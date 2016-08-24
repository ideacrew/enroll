puts "*"*80
puts "::: Cleaning ApplicationEventKinds :::"
ApplicationEventKind.delete_all

shop_notice_triggers = [
  {
    hbx_id: 'SHOP1A',
    title: 'Initial Employer SHOP Application Approval',
    description: 'ER application requirements met SHOP participation approved',
    resource_name: 'employer',
    event_name: 'application_accepted',
    notice_triggers: [
      {
        name: 'Employer notice trigger',
        notice_template: 'notices/shop_notices/1a_application_approval',
        notice_builder: 'ShopNotices::EmployerNotice',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ] 
  },
  {
    hbx_id: 'SHOP1B',
    title: 'Request for Clarifying Documentation',
    description: 'User has 30 calendar days to respond to this notice from the notice date',
    resource_name: 'employer',
    event_name: 'application_declined',
    notice_triggers: [
      {
        name: 'Employer notice trigger',
        notice_template: 'notices/shop_notices/1b_request_documents',
        notice_builder: 'ShopNotices::EmployerNotice',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ] 
  },
  {
    hbx_id: 'SHOP1C',
    title: 'Approval of Employer SHOP Application after Request for Clarifying Documentation',
    description: 'ER application requirements met SHOP participation approved',
    resource_name: 'employer',
    event_name: 'benefit_coverage_initial_binder_paid',
    notice_triggers: [
      {
        name: 'Employer notice trigger',
        notice_template: 'notices/shop_notices/1c_application_approval',
        notice_builder: 'ShopNotices::EmployerNotice',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ] 
  },
  {
    hbx_id: 'SHOP3A',
    title: 'Renewal/Conversion Employer Publishes Plan',
    description: 'Application to Offer Group Health Coverage in DC Health Link',
    resource_name: 'employer',
    event_name: 'planyear_renewal_3a',
    notice_triggers: [
      {
        name: 'PlanYear Renewal',
        notice_template: 'notices/shop_notices/3a_3b_employer_plan_year_renewal',
        notice_builder: 'ShopNotices::EmployerNotice',
        mpi_indicator: 'MPI_SHOPRA',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ] 
  },
  {
    hbx_id: 'SHOP3B',
    title: 'Renewal/Conversion Employer Auto-Published',
    description: 'Application to Offer Group Health Coverage in DC Health Link',
    resource_name: 'employer',
    event_name: 'planyear_renewal_3b',
    notice_triggers: [
      {
        name: 'PlanYear Renewal Auto-Published',
        notice_template: 'notices/shop_notices/3a_3b_employer_plan_year_renewal',
        notice_builder: 'ShopNotices::EmployerNotice',
        mpi_indicator: 'MPI_SHOPRB',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ] 
  },
]


ivl_notice_triggers = [
  {
    hbx_id: 'VerificationBacklog',
    title: 'Documents needed to confirm eligibility for your plan',
    description: 'Should be triggered for thoso who completed Enroll App application but verifications pending',
    resource_name: 'consumer_role',
    event_name: 'verifications_backlog',
    notice_triggers: [
      {
        name: 'Outstanding Verification Notification',
        notice_template: 'notices/ivl/verifications_backlog_notice',
        notice_builder: 'IvlNotices::ConsumerNotice',
        mpi_indicator: 'MPI_IVLV5B',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'Notice20A',
    title: 'Request for Additional Information - First Reminder',
    description: 'After 10 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'first_verifications_reminder',
    notice_triggers: [
      {
        name: 'First Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder1',
        notice_builder: 'IvlNotices::ConsumerNotice',
        mpi_indicator: 'MPI_IVLV20A',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ] 
  },
  {
    hbx_id: 'Notice20B',
    title: 'Request for Additional Information - Second Reminder',
    description: 'After 25 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'second_verifications_reminder',
    notice_triggers: [
      {
        name: 'Second Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder2',
        notice_builder: 'IvlNotices::ConsumerNotice',
        mpi_indicator: 'MPI_IVLV20B',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'Notice21',
    title: 'Request for Additional Information - Third Reminder',
    description: 'After 50 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'third_verifications_reminder',
    notice_triggers: [
      {
        name: 'Third Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder3',
        notice_builder: 'IvlNotices::ConsumerNotice',
        mpi_indicator: 'MPI_IVLV21',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'Notice22',
    title: 'Request for Additional Information - Fourth Reminder',
    description: 'After 65 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'fourth_verifications_reminder',
    notice_triggers: [
      {
        name: 'Fourth Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder4',
        notice_builder: 'IvlNotices::ConsumerNotice',
        mpi_indicator: 'MPI_IVLV22',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  }
]


shop_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end

ivl_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end



