# This rake task produces an csv report providing all brokers 
# and GA staff that have had a claim URL sent to them upon Admin Approval
require 'csv'

namespace :reports do
  namespace :shop do
    desc "All Brokers and GA Staff have had a claim URL sent to them upon Admin Approval"
    task :brokers_and_ga_staff_with_URL_from_admin_approval => :environment do
      include Config::AcaHelper

      broker_invitations = Invitation.where(:role.in => ["broker_role","broker_agency_staff_role"])
      broker_agency_field_names  = %w(
        Broker_Agency_Legal_Name
      )
      general_agency_invitations = Invitation.where(role: "general_agency_staff_role")
      general_agency_field_names = %w(
        General_Agency_Legal_Name
      )
      shared_field_names = %w(
        First_Name
        Last_Name
        Email
        Date_of_Unique_URL_being_sent
        Unique_URL
      )
      broker_processed_count = 0
      general_agency_processed_count = 0

      br_file_name = fetch_file_format(
        'brokers_list_with_URL_from_admin_approval',
        'BROKERSANDGASTAFFLISTWITHURLFROMADMINAPPROVAL'
      )

      ga_file_name = fetch_file_format(
        'ga_staff_list_with_URL_from_admin_approval',
        'BROKERSANDGASTAFFLISTWITHURLFROMADMINAPPROVAL'
      )

      CSV.open(br_file_name, "w", force_quotes: true) do |csv|
        csv << broker_agency_field_names + shared_field_names
        broker_invitations.each do |invitation|
          broker = BrokerRole.find(invitation.source_id.to_s)
          broker = BrokerAgencyStaffRole.find(invitation.source_id.to_s) if broker.blank?
          if broker.present?
            csv << [
              broker&.broker_agency_profile&.legal_name,
              broker.person.first_name,
              broker.person.last_name,
              broker.email_address,
              invitation.created_at,
              "http://enroll.dchealthlink.com/invitations/#{invitation.id}/claim"
            ]
            broker_processed_count += 1
          end
        end
      end

      CSV.open(ga_file_name, "w", force_quotes: true) do |csv|
        csv << general_agency_field_names + shared_field_names
        general_agency_invitations.each do |invitation|
          ga_staff_role = GeneralAgencyStaffRole.find(invitation.source_id.to_s)
          if ga_staff_role.present?
            csv << [
                ga_staff_role&.general_agency_profile&.legal_name,
                ga_staff_role.person.first_name,
                ga_staff_role.person.last_name,
                ga_staff_role.email_address,
                invitation.created_at,
            "http://enroll.dchealthlink.com/invitations/#{invitation.id}/claim"
            ]
            general_agency_processed_count += 1
          end
        end
      end

      if Rails.env.production?
        pubber = Publishers::Legacy::ShopBrokersWithAdminUrlReportPublisher.new
        pubber.publish URI.join("file://", br_file_name)
        pubber.publish URI.join("file://", ga_file_name)
      end

      puts "#{broker_processed_count} Brokers to output file: #{br_file_name}."
      puts "#{general_agency_processed_count} General Agency Staff to output file: #{ga_file_name}."
    end
  end
end
