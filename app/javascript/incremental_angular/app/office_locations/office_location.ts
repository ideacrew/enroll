import { Phone } from 'app/contact_information/phone';
import { Address } from './address';

export interface OfficeLocation {
  kind:  string;
  phone: Phone;
  address: Address;
}