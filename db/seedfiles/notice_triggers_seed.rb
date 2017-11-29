puts "*"*80
puts "::: Cleaning ApplicationEventKinds :::"
ApplicationEventKind.delete_all

shop_notice_triggers = [
    {
        hbx_id: 'SHOP_M001',
        title: 'Welcome to The Health Connector',
        description: 'ER creates an account in Health Connector',
        resource_name: 'employer',
        event_name: 'application_created',
        notice_triggers: [
            {
                name: 'Welcome Notice sent to Employer',
                notice_template: 'notices/shop_employer_notices/0_welcome_notice_employer',
                notice_builder: 'ShopEmployerNotices::WelcomeEmployerNotice',
                mpi_indicator: 'SHOP_M001',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employer"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                }
            }
        ]
    },

    # {
    #   hbx_id: 'SHOP1A',
    #   title: 'Initial Employer SHOP Application Approval',
    #   description: 'ER application requirements met SHOP participation approved',
    #   resource_name: 'employer',
    #   event_name: 'application_accepted',
    #   notice_triggers: [
    #     {
    #       name: 'Employer notice trigger',
    #       notice_template: 'notices/shop_employer_notices/1a_application_approval',
    #       notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP1B',
    #   title: 'Request for Clarifying Documentation',
    #   description: 'User has 30 calendar days to respond to this notice from the notice date',
    #   resource_name: 'employer',
    #   event_name: 'application_declined',
    #   notice_triggers: [
    #     {
    #       name: 'Employer notice trigger',
    #       notice_template: 'notices/shop_employer_notices/1b_request_documents',
    #       notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP1C',
    #   title: 'Approval of Employer SHOP Application after Request for Clarifying Documentation',
    #   description: 'ER application requirements met SHOP participation approved',
    #   resource_name: 'employer',
    #   event_name: 'benefit_coverage_initial_binder_paid',
    #   notice_triggers: [
    #     {
    #       name: 'Employer notice trigger',
    #       notice_template: 'notices/shop_employer_notices/1c_application_approval',
    #       notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    {
        hbx_id: 'SHOP_M002',
        title: 'Approval of Application to Offer Group Health Coverage through the Health Connector',
        description: 'Application to Offer Group Health Coverage in Health Connector',
        resource_name: 'employer',
        event_name: 'initial_employer_approval',
        notice_triggers: [
            {
                name: 'Initial Employer SHOP Approval Notice',
                notice_template: 'notices/shop_employer_notices/2_initial_employer_approval_notice',
                notice_builder: 'ShopEmployerNotices::InitialEmployerEligibilityNotice',
                mpi_indicator: 'SHOP_M002',
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
        hbx_id: 'SHOP_M003',
        title: 'Employer Denial Notice',
        description: 'Application to Offer Group Health Coverage in Health Connector',
        resource_name: 'employer',
        event_name: 'initial_employer_denial',
        notice_triggers: [
            {
                name: 'Denial of Initial Employer Application/Request for Clarifying Documentation',
                notice_template: 'notices/shop_employer_notices/2_initial_employer_denial_notice',
                notice_builder: 'ShopEmployerNotices::InitialEmployerDenialNotice',
                mpi_indicator: 'SHOP_M003',
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
    hbx_id: 'SHOP_M008',
    title: 'Action Needed – Add all Eligible Employees to your Roster',
    description: 'This notice goes to all the employers with zero employees on roster when published',
    resource_name: 'employer',
    event_name: 'zero_employees_on_roster',
    notice_triggers: [
      {
        name: 'Zero Employees on Rotser',
        notice_template: 'notices/shop_employer_notices/notice_for_employers_with_zero_employees_on_roster',
        notice_builder: 'ShopEmployerNotices::ZeroEmployeesOnRoster',
        mpi_indicator: 'SHOP_M008',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },

    # {
    #   hbx_id: 'SHOP3A',
    #   title: 'Plan Offerings Finalized',
    #   description: 'Application to Offer Group Health Coverage in DC Health Link when an Employer publishes PlanYear',
    #   resource_name: 'employer',
    #   event_name: 'planyear_renewal_3a',
    #   notice_triggers: [
    #     {
    #       name: 'PlanYear Renewal',
    #       notice_template: 'notices/shop_employer_notices/3a_employer_plan_year_renewal',
    #       notice_builder: 'ShopEmployerNotices::RenewalEmployerEligibilityNotice',
    #       mpi_indicator: 'MPI_SHOPRA',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP3B',
    #   title: 'Plan Offerings Finalized',
    #   description: 'Application to Offer Group Health Coverage in DC Health Link when an Employer PlanYear is force published',
    #   resource_name: 'employer',
    #   event_name: 'planyear_renewal_3b',
    #   notice_triggers: [
    #     {
    #       name: 'PlanYear Renewal Auto-Published',
    #       notice_template: 'notices/shop_employer_notices/3b_employer_plan_year_renewal',
    #       notice_builder: 'ShopEmployerNotices::RenewalEmployerEligibilityNotice',
    #       mpi_indicator: 'MPI_SHOPRB',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    # {
    #   hbx_id: 'SHOP5',
    #   title: 'Group Renewal Available',
    #   description: 'Notice will be sent to the Renewal Groups three months prior to their plan year renewing',
    #   resource_name: 'employer',
    #   event_name: 'group_renewal_5',
    #   notice_triggers: [
    #     {
    #       name: 'Group Renewal Notice',
    #       notice_template: 'notices/shop_employer_notices/5_employer_renewal_notice',
    #       notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
    #       mpi_indicator: 'MPI_SHOP5',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    # {
    #   hbx_id: 'SHOP6',
    #   title: 'Welcome to DC Health Link, Group Renewal Available',
    #   description: 'Renewing Your Health Insurance Coverage for Your Small Business on November 1, 2016',
    #   resource_name: 'employer',
    #   event_name: 'conversion_group_renewal',
    #   notice_triggers: [
    #     {
    #       name: 'Conversion, Group Renewal Available',
    #       notice_template: 'notices/shop_employer_notices/6_conversion_group_renewal_notice',
    #       notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
    #       mpi_indicator: 'MPI_SHOP6',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP6',
    #   title: 'Action Needed – Add all Eligible Employees to your Roster',
    #   description: 'This notice goes to all the employers with zero employees on roster when published',
    #   resource_name: 'employer',
    #   event_name: 'zero_employees_on_roster',
    #   notice_triggers: [
    #     {
    #       name: 'Zero Employees on Rotser',
    #       notice_template: 'notices/shop_employer_notices/notice_for_employers_with_zero_employees_on_roster',
    #       notice_builder: 'ShopEmployerNotices::ZeroEmployeesOnRoster',
    #       mpi_indicator: 'MPI_SHOP6',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP8A',
    #   title: 'Your Health Plan Open Enrollment Period has Begun',
    #   description: 'All the employees that are active in coverage and have an auto-renewal plan option available.',
    #   resource_name: 'employee_role',
    #   event_name: 'employee_open_enrollment_auto_renewal',
    #   notice_triggers: [
    #     {
    #       name: 'Renewal Open Enrollment available for Employee',
    #       notice_template: 'notices/shop_employee_notices/8a_renewal_open_enrollment_notice_for_employee',
    #       notice_builder: 'ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal',
    #       mpi_indicator: 'MPI_SHOP8A',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employee"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP8B',
    #   title: 'Your Health Plan Open Enrollment Period has Begun',
    #   description: 'All employees that enrolled the previous year and do not have an auto-renewal plan option available.',
    #   resource_name: 'employee_role',
    #   event_name: 'employee_open_enrollment_no_auto_renewal',
    #   notice_triggers: [
    #     {
    #       name: 'Renewal Open Enrollment available for Employee',
    #       notice_template: 'notices/shop_employee_notices/8b_renewal_open_enrollment_notice_for_employee',
    #       notice_builder: 'ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal',
    #       mpi_indicator: 'MPI_SHOP8B',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employee"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },
    # {
    #   hbx_id: 'SHOP8C',
    #   title: 'Your Health Plan Open Enrollment Period has Begun',
    #   description: 'All employees that are not currently enrolled in a plan',
    #   resource_name: 'employee_role',
    #   event_name: 'employee_open_enrollment_unenrolled',
    #   notice_triggers: [
    #     {
    #       name: 'Renewal Open Enrollment available for Employee',
    #       notice_template: 'notices/shop_employee_notices/8c_renewal_open_enrollment_notice_for_unenrolled_employee',
    #       notice_builder: 'ShopEmployeeNotices::OpenEnrollmentNoticeForUnenrolled',
    #       mpi_indicator: 'MPI_SHOP8C',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employee"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

     {
        hbx_id: 'SHOP_M015',
        title: 'Notice of Low Enrollment - Action Needed',
        description: 'Notifies all the employers who doesnt meet minimum participation requirement',
        resource_name: 'employer',
        event_name: 'low_enrollment_notice_for_employer',
        notice_triggers: [
          {
            name: 'Low Enrollment Notice',
            notice_template: 'notices/shop_employer_notices/low_enrollment_notice_for_employer',
            notice_builder: 'ShopEmployerNotices::LowEnrollmentNotice',
            mpi_indicator: 'SHOP_M015',
            notice_trigger_element_group: {
              market_places: ['shop'],
              primary_recipients: ["employer"],
              primary_recipient_delivery_method: ["secure_message"],
              secondary_recipients: []
            }
          }
        ]
      },

    # {
    #   hbx_id: 'SHOP16',
    #   title: 'Application to Offer Group Health Coverage in DC Health Link',
    #   description: 'When Employer application meets minimum participation and non-owner requirements',
    #   resource_name: 'employer',
    #   event_name: 'initial_eligibile_employer_open_enrollment_begins',
    #   notice_triggers: [
    #     {
    #       name: 'Initial Eligible Employer open enrollment begins',
    #       notice_template: 'notices/shop_employer_notices/initial_employer_open_enrollment_begins',
    #       notice_builder: 'ShopEmployerNotices::InitialEmployerOpenEnrollmentBegin',
    #       mpi_indicator: 'MPI_SHOP16',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    # {
    #   hbx_id: 'SHOP16_B',
    #   title: 'Initial Eligible Employee Open Enrollment Period begins',
    #   description: 'When Employer application meets minimum participation and non-owner requirements',
    #   resource_name: 'employee_role',
    #   event_name: 'initial_employee_open_enrollment_begins',
    #   notice_triggers: [
    #     {
    #       name: 'Initial Eligible Employee open enrollment begins',
    #       notice_template: 'notices/shop_employee_notices/16b_initial_employee_open_enrollment_begins',
    #       notice_builder: 'ShopEmployeeNotices::InitialEmployeeOpenEnrollmentBegin',
    #       mpi_indicator: 'MPI_SHOP16_B',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employee"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    {
        hbx_id: 'SHOP_M017',
        title: 'Open Enrollment Completed',
        description: 'All initial Employers who complete their initial Open Enrollment Period and satisfy the minimum participation and non-owner enrollmnet requirements',
        resource_name: 'employer',
        event_name: 'initial_employer_open_enrollment_completed',
        notice_triggers: [
            {
                name: 'Initial Employee Open Enrollment Successfully Completed',
                notice_template: 'notices/shop_employer_notices/17_initial_employer_open_enrollment_completed',
                notice_builder: 'ShopEmployerNotices::InitialEmployerOpenEnrollmentCompleted',
                mpi_indicator: 'SHOP_M017',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employer"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                }
            }
        ]
    },

    # {
    #   hbx_id: 'SHOP13',
    #   title: 'Open Enrollment Reminder',
    #   description: 'This notices goes to all the employees in the open enrollment period',
    #   resource_name: 'employee_role',
    #   event_name: 'employee_open_enrollment_reminder',
    #   notice_triggers: [
    #     {
    #       name: 'Employee Open Enrollment Reminder Notice',
    #       notice_template: 'notices/shop_employee_notices/13_employee_open_enrollment_reminder',
    #       notice_builder: 'ShopEmployeeNotices::EmployeeOpenEnrollmentReminderNotice',
    #       mpi_indicator: 'MPI_SHOP13',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employee"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    {
        hbx_id: 'SHOP_M020',
        title: 'Initial Ineligible to Obtain Coverage',
        description: 'Notice goes to Initial groups who did not meet Minimum Participation Requirement or non-owner enrollee requirement after open enrollment is completed.',
        resource_name: 'employer',
        event_name: 'initial_employer_ineligibility_notice',
        notice_triggers: [
            {
                name: 'Initial Group Ineligible to Obtain Coverage',
                notice_template: 'notices/shop_employer_notices/20_a_initial_employer_ineligibility_notice',
                notice_builder: 'ShopEmployerNotices::InitialEmployerIneligibilityNotice',
                mpi_indicator: 'SHOP_M020',
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
      hbx_id: 'SHOP_M049',
      title: 'You Removed Your Broker In The Health Connector',
      description: ' Broker gets terminated after employer selects change broker',
      resource_name: 'employer',
      event_name: 'employer_broker_fired',
      notice_triggers: [
          {
              name: 'YOU REMOVED YOUR BROKER IN THE HEALTH CONNECTOR',
              notice_template: 'notices/shop_employer_notices/employer_broker_fired_notice',
              notice_builder: 'ShopEmployerNotices::EmployerBrokerFiredNotice',
              mpi_indicator: 'SHOP_M049',
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
        hbx_id: 'SHOP_M022',
        title: 'Your Invoice for Employer Sponsored Coverage is Now Available',
        description: 'When initial groups first invoice is available in their account, this notice is sent to them to instruct them on how to pay their binder payment.',
        resource_name: 'employer',
        event_name: 'initial_employer_invoice_available',
        notice_triggers: [
            {
                name: 'Initial Employer first invoice available in the account',
                notice_template: 'notices/shop_employer_notices/initial_employer_invoice_available_notice',
                notice_builder: 'ShopEmployerNotices::InitialEmployerInvoiceAvailable',
                mpi_indicator: 'SHOP_M022',
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
      hbx_id: 'SHOP_M057',
      title: 'Denial Of Application To Offer Group Health Coverage In The Massachusetts Health Connector',
      description: 'Denial Of Application To Offer Group Health Coverage In The Massachusetts Health Connector',
      resource_name: 'employer',
      event_name: 'employer_ineligibilty_denial_application',
      notice_triggers: [
          {
              name: 'DENIAL OF APPLICATION TO OFFER GROUP HEALTH COVERAGE IN THE MASSACHUSETTS HEALTH CONNECTOR',
              notice_template: 'notices/shop_employer_notices/initial_shop_application_is_denied_after_request_for_clarifying_documentation',
              notice_builder: 'ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation',
              mpi_indicator: 'SHOP_M057',
              notice_trigger_element_group: {
                  market_places: ['shop'],
                  primary_recipients: ["employer"],
                  primary_recipient_delivery_method: ["secure_message"],
                  secondary_recipients: []
              }
          }
      ]
    },
    # {
    #   hbx_id: 'SHOP27',
    #   title: 'Final Reminder to publish Application',
    #   description: 'All the initial employers with draft plan years will be notified to publish their plan year on 3rd of the month.',
    #   resource_name: 'employer',
    #   event_name: 'initial_employer_final_reminder_to_publish_plan_year',
    #   notice_triggers: [
    #     {
    #       name: 'Initial Employer Application, Deadline Extended - Reminder to publish',
    #       notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
    #       notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
    #       mpi_indicator: 'MPI_SHOP27',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },

    # {
    #   hbx_id: 'SHOP28',
    #   title: 'Final Reminder to publish Application',
    #   description: 'All the initial employers with draft plan years will be notified to publish their plan year 1 day prior to soft deadline of 1st.',
    #   resource_name: 'employer',
    #   event_name: 'initial_employer_final_reminder_to_publish_plan_year',
    #   notice_triggers: [
    #     {
    #       name: 'Initial Employer Application, Deadline Extended - Reminder to publish',
    #       notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
    #       notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
    #       mpi_indicator: 'MPI_SHOP28',
    #       notice_trigger_element_group: {
    #         market_places: ['shop'],
    #         primary_recipients: ["employer"],
    #         primary_recipient_delivery_method: ["secure_message"],
    #         secondary_recipients: []
    #       }
    #     }
    #   ]
    # },


   {
    hbx_id: 'SHOP26',
    title: 'Action Required to complete Employer Application',
    description: 'All the initial employers with draft plan years will be notified to publish their plan year 2 days prior to soft deadline of 1st.',
    resource_name: 'employer',
    event_name: 'initial_employer_first_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Initial Employer Application - Reminder to publish',
        notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
        mpi_indicator: 'SHOP_M026',
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
    hbx_id: 'SHOP28',
    title: 'Final Reminder – Action Required to Complete Employer Application',
    description: 'All the initial employers with draft plan years will be notified to publish their plan year on 3rd of the month.',
    resource_name: 'employer',
    event_name: 'initial_employer_final_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Initial Employer Application, Deadline Extended - Reminder to publish',
        notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
        mpi_indicator: 'SHOP_M028',
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
    hbx_id: 'SHOP27',
    title: 'Action Required to Complete Employer Application – Deadline Extended',
    description: 'All the initial employers with draft plan years will be notified to publish their plan year 1 day prior to soft deadline of 1st.',
    resource_name: 'employer',
    event_name: 'initial_employer_second_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Initial Employer Application, Deadline Extended - Reminder to publish',
        notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
        mpi_indicator: 'SHOP_M027',
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
        hbx_id: 'SHOP58',
        title: "Notice To Initial Employer's No Binder Payment Received",
        description: 'When an initial employer misses the binder payment deadline, this is sent the day after the binder payment deadline.',
        resource_name: 'employer',
        event_name: 'initial_employer_no_binder_payment_received',
        notice_triggers: [
            {
                name: ' Initial Employer No Binding Payment Received',
                notice_template: 'notices/shop_employer_notices/notice_to_employer_no_binder_payment_received',
                notice_builder: 'ShopEmployerNotices::NoticeToEmployerNoBinderPaymentReceived',
                mpi_indicator: 'SHOP_M058',
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
        hbx_id: 'SHOP32',
        title: 'EE SEP Requested Enrollment Period Approval Notice',
        description: 'Notification to Employee Regarding SEP Request Enrollment Approval',
        resource_name: 'employee_role',
        event_name: 'notify_employee_of_special_enrollment_period',
        notice_triggers: [
            {
                name: 'Notification to employee regarding their Special enrollment period',
                notice_template: 'notices/shop_employee_notices/notification_to_employee_due_to_sep',
                notice_builder: 'ShopEmployeeNotices::EmployeeSepQleAcceptNotice',
                mpi_indicator: 'SHOP_M032',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []

                }
            }
        ]
    },

    {
        hbx_id: 'SHOP33',
        title: 'Special Enrollment Period Denial',
        description: 'EE SEP Requested by Employee outside of allowable time frame',
        resource_name: 'employee_role',
        event_name: 'sep_request_denial_notice',
        notice_triggers: [
            {
                name: 'Denial of SEP Requested by EE outside of allowable time frame',
                notice_template: 'notices/shop_employee_notices/sep_request_denial_notice',
                notice_builder: 'ShopEmployeeNotices::SepRequestDenialNotice',
                mpi_indicator: 'SHOP_M033',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                }
            }
        ]
    },

    {
        hbx_id: 'SHOP_M038',
        title: 'Termination of Employer’s Health Coverage Offered through the Massachusetts Health Connector',
        description: 'Notification to employees regarding their Employer’s ineligibility.',
        resource_name: 'employee_role',
        event_name: 'notify_employee_of_initial_employer_ineligibility',
        notice_triggers: [
            {
                name: 'Notification to employees regarding their Employer’s ineligibility.',
                notice_template: 'notices/shop_employee_notices/notification_to_employee_due_to_initial_employer_ineligibility',
                notice_builder: 'ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility',
                mpi_indicator: 'SHOP_M038',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                }
            }
        ]
    },

    {                
        hbx_id: 'SHOP42',
        title: 'Termination of Employer’s Health Coverage Offered Through The Health Connector',
        description: 'When an employer request termination at least 30 days in advance, all employees active on their roster will receive this notice to provide confirmation of the request and the coverage end date for their groups termination of coverage.',
        resource_name: 'employee_role',
        event_name: 'notify_employee_when_employer_requests_advance_termination', 
        notice_triggers: [
          {
            name: " Notice to EEs that active ER is terminated from SHOP",
            notice_template: 'notices/shop_employee_notices/notice_to_employees_that_active_er_is_terminated_from_shop',
            notice_builder: 'ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop',
            mpi_indicator: 'SHOP_M042',
            notice_trigger_element_group: {
                  market_places: ['shop'],
                  primary_recipients: ["employee"],
                  primary_recipient_delivery_method: ["secure_message"],
                  secondary_recipients: []
                }
            }
        ]
    },


    {
        hbx_id: 'SHOP_M039',
        title: 'Employee Terminating coverage',
        description: 'Employee Terminating coverage after QLE',
        resource_name: 'employer',
        event_name: 'notify_employer_when_employee_terminate_coverage',
        notice_triggers: [
          {
            name: 'Notice to employer when employee terminates coverage',
            notice_template: 'notices/employee_terminating_coverage',
            notice_builder: 'EmployeeTerminatingCoverage',
            mpi_indicator: 'SHOP_M039',
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
   hbx_id: 'SHOP46',
   title: 'Broker Hired Confirmation Notice',
   description: 'Confirmation of Broker Hired Sent to Employer',
   resource_name: 'employer',
   event_name: 'broker_hired_confirmation',
   notice_triggers: [
     {
       name: 'Boker Hired Confirmation',
       notice_template: 'notices/shop_employer_notices/broker_hired_confirmation_notice',
       notice_builder: 'ShopEmployerNotices::BrokerHiredConfirmationNotice',
       mpi_indicator: 'SHOP_M046',
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
        hbx_id: 'SHOP45',
        title: 'You have been Hired as a Broker',
        description: "When a broker is hired to a group, a notice is sent to the broker's broker mail inbox alerting them of the hire.",
        resource_name: 'broker_role',
        event_name: 'broker_hired',
        notice_triggers: [
           {
              name: 'Broker Hired',
              notice_template: 'notices/shop_broker_notices/broker_hired_notice',
              notice_builder: 'ShopBrokerNotices::BrokerHiredNotice',
              mpi_indicator: 'SHOP_M045',
              notice_trigger_element_group: {
                market_places: ['shop'],
                primary_recipients: ["broker"],
                primary_recipient_delivery_method: ["secure_message"],
                secondary_recipients: []
              }
            }
        ]
    },

    {
        hbx_id: 'SHOP44',
        title: 'You have been Hired as a Broker',
        description: "When a broker is hired to a group, a notice is sent to the broker's broker mail inbox alerting them of the hire.",
        resource_name: 'broker_role',
        event_name: 'broker_agency_hired_confirmation',
        notice_triggers: [
           {
              name: 'Broker Agency Hired',
              notice_template: 'notices/shop_broker_agency_notices/broker_agency_hired_notice',
              notice_builder: 'ShopBrokerAgencyNotices::BrokerAgencyHiredNotice',
              mpi_indicator: 'SHOP_M044',
              notice_trigger_element_group: {
                market_places: ['shop'],
                primary_recipients: ["broker"],
                primary_recipient_delivery_method: ["secure_message"],
                secondary_recipients: []
              }
            }
        ]
    },
    {
        hbx_id: 'SHOP48',
        title: 'You have been removed as a Broker',
        description: "When a Broker is fired by an employer, the broker receives this notification letting them know they are no longer the broker for the client.",
        resource_name: 'broker_role',
        event_name: 'broker_fired_confirmation_to_broker',
        notice_triggers: [
           {
              name: 'Broker Fired',
              notice_template: 'notices/shop_broker_notices/broker_fired_notice',
              notice_builder: 'ShopBrokerNotices::BrokerFiredNotice',
              mpi_indicator: 'SHOP_M048',
              notice_trigger_element_group: {
                market_places: ['shop'],
                primary_recipients: ["broker"],
                primary_recipient_delivery_method: ["secure_message"],
                secondary_recipients: []
              }
            }
        ]
    },
    {
        hbx_id: 'SHOP47',
        title: 'You have been removed as a Broker',
        description: "When a broker is fired, a notice is sent to the broker's broker mail inbox alerting them of the hire.",
        resource_name: 'broker_role',
        event_name: 'broker_agency_fired_confirmation',
        notice_triggers: [
           {
              name: 'Broker Agency Fired',
              notice_template: 'notices/shop_broker_agency_notices/broker_agency_fired_notice',
              notice_builder: 'ShopBrokerAgencyNotices::BrokerAgencyFiredNotice',
              mpi_indicator: 'SHOP_M047',
              notice_trigger_element_group: {
                market_places: ['shop'],
                primary_recipients: ["broker"],
                primary_recipient_delivery_method: ["secure_message"],
                secondary_recipients: []
              }
            }
        ]
    },

    {
        hbx_id: 'SHOP56',
        title: 'Approval Of Application To Offer Group Health Coverage',
        description: 'Manual trigger when a SHOP Tier 2 team member creates a redmine ticket to generate Approval notice',
        resource_name: 'employer',
        event_name: 'initial_shop_application_approval',
        notice_triggers: [
            {
                name: 'Notice sent to employer when initial shop application is approved after Request for Clarifying Documentation',
                notice_template: 'notices/shop_employer_notices/initial_shop_application_approval_notice',
                notice_builder: 'ShopEmployerNotices::InitialShopApplicationApprovalNotice',
                mpi_indicator: 'SHOP_M056',
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
        hbx_id: 'SHOP_M068',
        title: 'Employee Plan Selection Confirmation',
        description: 'Employee selects a plan during annual open enrollement OE is still open and not final confirmation',
        resource_name: 'employee_role',
        event_name: 'select_plan_year_during_oe',
        notice_triggers: [
            {
                name: 'Notice to employee after they select a plan during Annual Open Enrollment',
                notice_template: 'notices/shop_employee_notices/15_employee_select_plan_during_annual_open_enrollment',
                notice_builder: 'ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment',
                mpi_indicator: 'SHOP_M068',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                }
            }
        ]
    },
    {
      hbx_id: 'SHOP_M070',
      title: 'Employee Enrollment Confirmation',
      description: 'Employee selects a plan during annual open enrollment OE is still close and final confirmation',
      resource_name: 'employee_role',
      event_name: 'initial_employee_plan_selection_confirmation',
      notice_triggers: [
        {
            name: 'Notice to employee after they select a plan Annual Open Enrollment',
            notice_template: 'notices/shop_employee_notices/initial_employee_plan_selection_confirmation',
            notice_builder: 'ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation',
            mpi_indicator: 'SHOP_M070',
            notice_trigger_element_group: {
                market_places: ['shop'],
                primary_recipients: ["employee"],
                primary_recipient_delivery_method: ["secure_message"],
                secondary_recipients: []
            }
        }
      ]
    },
    {
        hbx_id: 'SHOP_M040',
        title: 'CONFIRMATION OF ELECTION TO TERMINATE COVERAGE',
        description: 'Employee Terminating coverage after QLE',
        resource_name: 'employer',
        event_name: 'notify_employee_confirming_coverage_termination',
        notice_triggers: [
            {
                name: 'Notice to employer when employee terminates coverage',
                notice_template: 'notices/shop_employee_notices/employee_terminating_coverage',
                notice_builder: 'ShopEmployeeNotices::EmployeeTerminatingCoverage',
                # used unique MPI indicator with two event names
                mpi_indicator: 'SHOP_M040',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                     primary_recipients: ["employer"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []        }
            }
        ]
    },
    {
        hbx_id: 'SHOP_M041',
        title: 'Notice Confirmation for Group termination due to ER advance request',
        description: 'Group termination confirmation for advance request',
        resource_name: 'employer',
        event_name: 'group_advance_termination_confirmation',
        notice_triggers: [
            {
                name: 'Notice to employee after they select a plan Annual Open Enrollment',
                notice_template: 'notices/shop_employer_notices/group_advance_termination_confirmation',
                notice_builder: 'ShopEmployerNotices::GroupAdvanceTerminationConfirmation',
                mpi_indicator: 'SHOP_M041',
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
        hbx_id: 'SHOP_M053',
        title: 'EE Ineligibility Notice – Terminated from Roster',
        description: 'Employee must be notified when they are terminated from an ER roster that they are no longer eligible to enroll in coverage with that ER, effective DOT',
        resource_name: 'employee_role',
        event_name: 'employee_termination_notice',
        notice_triggers: [
          {
            name: 'Employee Termination Notice',
            notice_template: 'notices/shop_employee_notices/employee_termination_notice',
            notice_builder: 'ShopEmployeeNotices::EmployeeTerminationNotice',
            mpi_indicator: 'SHOP_M053',
            notice_trigger_element_group: {
                  market_places: ['shop'],
                  primary_recipients: ["employee"],
                  primary_recipient_delivery_method: ["secure_message"],
                  secondary_recipients: []
                }
            }
        ]
    },

    {
        hbx_id: 'SHOP_M029',
        title: 'Confirmation Of Election To Waive Coverage',
        description: 'Employee waiver confirmation',
        resource_name: 'employee_role',
        event_name: 'employee_waiver_notice',
        notice_triggers: [
            {
                name: 'Notice to employee after they select a plan Annual Open Enrollment',
                notice_template: 'notices/shop_employee_notices/employee_waiver_confirmation_notification',
                notice_builder: 'ShopEmployeeNotices::EmployeeWaiverConfirmNotice',
                mpi_indicator: 'SHOP_M029',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                }
            }
        ]
    },
    
    {                
        hbx_id: 'SHOP59',
        title: 'Termination of Employer’s Health Coverage Offered Through The Health Connector',
        description: 'When an initial group misses the binder payment deadline this notice is sent to employees to let them know the group will not be offering coverage',
        resource_name: 'employee_role',
        event_name: 'ee_ers_plan_year_will_not_be_written_notice', 
        notice_triggers: [
          {
                name: " Notice to EEs that ER’s plan year will not be written",
                notice_template: 'notices/shop_employee_notices/termination_of_employers_health_coverage',
                notice_builder: 'ShopEmployeeNotices::TerminationOfEmployersHealthCoverage',
                mpi_indicator: 'SHOP_M059',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []

                }
            }
        ]
    },        

    {
        hbx_id: 'SHOP_M040',
        title: 'CONFIRMATION OF ELECTION TO TERMINATE COVERAGE',
        description: 'Employee Terminating coverage after QLE',
        resource_name: 'employer',
        event_name: 'notify_employee_confirming_dental_coverage_termination',
        notice_triggers: [
            {
                name: 'Notice to employer when employee terminates coverage',
                notice_template: 'notices/shop_employee_notices/employee_terminating_dental_coverage',
                notice_builder: 'ShopEmployeeNotices::EmployeeTerminatingDentalCoverage',
                mpi_indicator: 'SHOP_M040',
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
        hbx_id: 'SHOP_M050',
        title: 'Eligible to Apply for Employer-sponsored Health Insurance',
        description: 'Employee completes initial application and matches the employee to a SHOP Employer (checks SSN and DOB against roster)',
        resource_name: 'employee_role',
        event_name: 'employee_matches_employer_rooster',
        notice_triggers: [
            {
                name: 'Employee must be notified when they successfully match to their employer',
                notice_template: 'notices/shop_employee_notices/employee_matches_employer_rooster_notification',
                notice_builder: 'ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice',
                mpi_indicator: 'SHOP_M050',
                notice_trigger_element_group: {
                    market_places: ['shop'],
                    primary_recipients: ["employee"],
                    primary_recipient_delivery_method: ["secure_message"],
                    secondary_recipients: []
                } 
            }
        ]
    },
    {
        hbx_id: 'SHOP_M043',
        title: 'EMPLOYEE has made a change to their employer-sponsored coverage selection',
        description: 'EE Made Mid-Year Plan Change (Reason: New Hire, SEP, OR DPT Age-Off)',
        resource_name: 'employer',
        event_name: 'employee_mid_year_plan_change',
        notice_triggers: [
          {
                name: 'Employee Mid-Year Plan change',
                notice_template: 'notices/shop_employer_notices/employee_mid_year_plan_change',
                notice_builder: 'EmployeeMidYearPlanChange',
                mpi_indicator: 'SHOP_M043',
                notice_trigger_element_group: {
                  market_places: ['shop'],
                  primary_recipients: ["employer"],
                  primary_recipient_delivery_method: ["secure_message"],
                  secondary_recipients: []
                }
            }
        ]
    }
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
    },

    {
        hbx_id: 'IVLR1',
        title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
        description: 'Notice to be sent out to individuals with UQHP(Unassisted)',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_1',
        notice_triggers: [
            {
                name: 'September Projected Renewal Notice',
                notice_template: 'notices/ivl/ivlr_1_uqhp_projected_renewal_notice',
                notice_builder: 'IvlNotices::IvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR1',
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
        hbx_id: 'IVLR1',
        title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
        description: 'Notice to be sent out to individuals with UQHP(Unassisted)',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_1_second_batch',
        notice_triggers: [
            {
                name: 'September Projected Renewal Notice',
                notice_template: 'notices/ivl/ivlr1_notice_second_batch_without_ea_data',
                notice_builder: 'IvlNotices::IvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR1B',
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
        hbx_id: 'IVLR2',
        title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
        description: 'Notice to be sent out to individuals staying in APTC only',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_2',
        notice_triggers: [
            {
                name: 'September Projected Renewal Notice',
                notice_template: 'notices/ivl/ivlr_2_projected_renewal_notice',
                notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR2',
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
        hbx_id: 'IVLR3',
        title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
        description: 'Notice to be sent out to individuals moving from APTC to Medicaid',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_3',
        notice_triggers: [
            {
                name: 'September Projected Renewal Notice',
                notice_template: 'notices/ivl/IVLR_3_APTC_Medicaid',
                notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR3',
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
        hbx_id: 'IVLR4',
        title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
        description: 'Notice to be sent out to individuals moving from APTC to UQHP',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_4',
        notice_triggers: [
            {
                name: 'September Projected Renewal Notice',
                notice_template: 'notices/ivl/IVLR4_APTC_uqhp',
                notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR4',
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
        hbx_id: 'IVLR8',
        title: '2017 Insurance Renewal Notice and Opportunity to Change Plans',
        description: 'Notice to be sent out to individuals staying on UQHP',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_8',
        notice_triggers: [
            {
                name: 'September Projected Renewal Notice - UQHP',
                notice_template: 'notices/ivl/IVLR8_UQHP_to_UQHP',
                notice_builder: 'IvlNotices::VariableIvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR8',
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
        hbx_id: 'IVLR9',
        title: 'Your 2017 Final Insurance Enrollment Notice',
        description: 'Notice to be sent out to people enrolled in 2017 coverage who have enrolled by December',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_9',
        notice_triggers: [
            {
                name: 'December Final Insurance Enrollment Notice',
                notice_template: 'notices/ivl/IVLR9_UQHP_final_renewal_december',
                notice_builder: 'IvlNotices::NoAppealVariableIvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR9',
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
        hbx_id: 'IVLR10',
        title: 'Your 2017 Final Insurance Enrollment Notice',
        description: 'Notice to be sent out to people enrolled in 2017 assisted coverage who have enrolled by December',
        resource_name: 'consumer_role',
        event_name: 'ivl_renewal_notice_10',
        notice_triggers: [
            {
                name: 'December Final Insurance Enrollment Notice',
                notice_template: 'notices/ivl/IVLR10_AQHP_final_renewal',
                notice_builder: 'IvlNotices::NoAppealVariableIvlRenewalNotice',
                mpi_indicator: 'MPI_IVLR10',
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
        hbx_id: 'IVL_CAT16',
        title: 'Important Tax Information about your Catastrophic Health Coverage',
        description: 'Notice to be sent out to all the people enrolled in Catastrophic plan in 2016 for at least one month',
        resource_name: 'consumer_role',
        event_name: 'final_catastrophic_plan_2016',
        notice_triggers: [
            {
                name: 'Final Catastrophic Plan Notice',
                notice_template: 'notices/ivl/final_catastrophic_plan_letter',
                notice_builder: 'IvlNotices::FinalCatastrophicPlanNotice',
                mpi_indicator: 'MPI_CAT16',
                notice_trigger_element_group: {
                    market_places: ['individual'],
                    primary_recipients: ["consumer"],
                    primary_recipient_delivery_method: ["secure_message", "paper"],
                    secondary_recipients: []
                }
            }
        ]
    },
]


shop_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end

puts "::: created Shop notice triggers ApplicationEventKinds Successfully :::"

# Since MA does not need IVL notices we are not triggering the IVL related notices
# ivl_notice_triggers.each do |trigger_params|
#   ApplicationEventKind.create(trigger_params)
# end