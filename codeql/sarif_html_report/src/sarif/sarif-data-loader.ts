import { Log, Run, ToolComponent, ReportingDescriptor, Result } from 'sarif';
import * as data from "../data/codeql.json";

export class SarifData {
  public errors = 0;
  public warnings = 0;
  public notes = 0;
  public infos = 0;
  public results = new Array<Result>();
  public rules = new Map<string, ReportingDescriptor>();
  private log = <Log | null>data;

  constructor() {
    this.analyze();
  }

  public analyze() {
    if (this.log) {
      for (const run of this.log.runs) {
        this.processRun(run);
      }
    }
  }

  private categorizeResult(result: Result) {
    let ruleId = result.ruleId;
    if (ruleId) {
      let matchingRule = this.rules.get(ruleId);
      if (matchingRule) {
        if (matchingRule.defaultConfiguration) {
          this.results.push(result);
          let defaultConfiguration = matchingRule.defaultConfiguration;
          if (defaultConfiguration.level === "error") {
            this.errors = this.errors + 1;
          } else if (defaultConfiguration.level === "warning") {
            this.warnings = this.warnings + 1;
          } else if (defaultConfiguration.level === "note") {
            this.notes = this.notes + 1;
          } else if (defaultConfiguration.level === "none") {
            this.infos = this.infos + 1;
          }
        }
      }
    }
  }

  private processRun(run : Run) {
    if (run.tool) {
      if (run.tool.driver !== undefined) {
        let driver = <ToolComponent>run.tool.driver;
        if (driver.rules) {
          for (var i = 0; i < driver.rules.length; i++) {
            this.rules.set(driver.rules[i].id, driver.rules[i]);
          }
        }
      }
    }
    if (run.results !== undefined) {
      for (var i = 0; i < run.results.length; i++) {
        this.categorizeResult(run.results[i]);
      }
    }
  }
}