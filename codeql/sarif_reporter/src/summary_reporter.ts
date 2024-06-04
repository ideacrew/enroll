import { Log, Run, ToolComponent, ReportingDescriptor, Result } from 'sarif';
import { IgnoreFile } from './ignore_file';

export class SummaryReporter {
  private errors = 0;
  private warnings = 0;
  private notes = 0;
  private infos = 0;

  constructor(private log: Log | undefined | null, private ignoreFile: IgnoreFile | null) {}

  public execute() : number {
    if (this.log) {
      for (const run of this.log.runs) {
        this.processRun(run);
      }
    }
    console.log("This application provides CodeQL summary metrics ONLY.");
    console.log("If you want to know why a CodeQL security check failed, run codeql_report.sh locally.\n\n\n");
    console.log("CodeQL Analysis Results:\n\n")
    console.log(`Errors: ${this.errors}`);
    console.log(`Warnings: ${this.warnings}`);
    console.log(`Notes: ${this.notes}`);
    console.log(`Info: ${this.infos}`);
    if (this.errors > 0 || this.warnings > 0) {
      return -1;
    }
    return 0;
  }

  private categorizeResult(rules: Map<string, ReportingDescriptor>, result: Result) {
    let ruleId = result.ruleId;
    if (ruleId) {
      if (this.ignoreFile && this.ignoreFile.entries && this.ignoreFile.entries.length > 0) {
        if (result.partialFingerprints) {
          const pllHash = result.partialFingerprints.primaryLocationLineHash;
          const plStartColumnFingerprint = result.partialFingerprints.primaryLocationStartColumnFingerprint;
          const matchingIgnores = this.ignoreFile.entries.filter((entry) => {
            return (pllHash == entry.fingerprint.primaryLocationLineHash) &&
              (plStartColumnFingerprint.toString() == entry.fingerprint.primaryLocationStartColumnFingerprint.toString()) &&
              (ruleId == entry.ruleId);
          });
          if (matchingIgnores.length > 0) {
            return;
          }
        }
      }
      let matchingRule = rules.get(ruleId);
      if (matchingRule) {
        if (matchingRule.defaultConfiguration) {
          let defaultConfiguration = matchingRule.defaultConfiguration;
          if (defaultConfiguration.level == "error") {
            this.errors = this.errors + 1;
          } else if (defaultConfiguration.level == "warning") {
            this.warnings = this.warnings + 1;
          } else if (defaultConfiguration.level == "note") {
            this.notes = this.notes + 1;
          } else if (defaultConfiguration.level == "none") {
            this.infos = this.infos + 1;
          }
        }
      }
    }
  }

  private processRun(run : Run) {
    let rules = new Map<string, ReportingDescriptor>();
    if (run.tool) {
      if (run.tool.driver != undefined) {
        let driver = <ToolComponent>run.tool.driver;
        if (driver.rules) {
          for (var i = 0; i < driver.rules.length; i++) {
            rules.set(driver.rules[i].id, driver.rules[i]);
          }
        }
      }
    }
    if (run.results != undefined) {
      for (var i = 0; i < run.results.length; i++) {
        this.categorizeResult(rules, run.results[i]);
      }
    }
  }
}
