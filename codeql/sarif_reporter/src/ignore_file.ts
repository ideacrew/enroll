import { parse, stringify } from 'yaml'
import { readFileSync } from 'fs'

export interface FingerPrint {
  primaryLocationLineHash: string,
  primaryLocationStartColumnFingerprint: string;
}

export interface IgnoreEntry {
  fingerprint: FingerPrint;
  ruleId: string;
  location: string;
  comment: string;
}

export class IgnoreFile {
  public readonly entries : Array<IgnoreEntry> ;

  constructor(private path: string) {
    console.log("Loading ignore file.\n\n");
    const fileData = readFileSync(path);
    this.entries = <Array<IgnoreEntry>>parse(fileData.toString());
  }
}