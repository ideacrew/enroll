import { Phone } from '../contact_information/phone';
import { Address } from '../office_locations/address';
import { OfficeLocation } from '../office_locations/office_location';
import { AchInformation } from 'app/financial/ach_information';

export interface BrokerAgencyProfileCreateModel {
  first_name: String;
  last_name: String;
  email: String;
  npn: String;
  dob: String;
  practice_area: String;
  languages: String[];
  evening_weekend_hours: Boolean;
  accepts_new_clients: Boolean;
  legal_name: String;
  dba: String;
  ach_information?: AchInformation;
  address: Address;
  phone: Phone;
  office_locations: OfficeLocation[];
}