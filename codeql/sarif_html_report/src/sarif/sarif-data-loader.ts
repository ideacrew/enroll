import { parse } from "yaml"
import { Log, Run, ToolComponent, ReportingDescriptor, Result, Notification } from 'sarif';
import * as data from "../data/codeql.json";


// eslint-disable-next-line import/no-webpack-loader-syntax
import yamlContent from "!!raw-loader!../data/ignore.yaml";


interface FingerPrint {
  primaryLocationLineHash: string,
  primaryLocationStartColumnFingerprint: string;
}

interface IgnoreEntry {
  fingerprint: FingerPrint;
  ruleId: string;
  location: string;
  comment: string;
}

export class SarifData {
  public errors = 0;
  public warnings = 0;
  public notes = 0;
  public infos = 0;
  public results = new Array<Result>();
  public notifications = new Array<Notification>();
  public rules = new Map<string, ReportingDescriptor>();
  public notificationTypes = new Map<string, ReportingDescriptor>();
  private log = <Log | null>data;
  public ignores = new Array<IgnoreEntry>();

  constructor() {
    console.log(yamlContent);
    this.analyze(yamlContent);
    console.log(this.ignores);
  }

  public analyze(yamldata : string) {
    if (yamldata) {
      const ignoreData = <Array<IgnoreEntry> | null>parse(yamldata);
      if (ignoreData) {
        this.ignores = ignoreData;
      }
    }
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

  private categorizeNotification(n: Notification) {
    if (n.level) {
      if ((n.level === "error") || (n.level === "warning")) {
        this.notifications.push(n);
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
        if (driver.notifications) {
          for (var j = 0; j < driver.notifications.length; j++) {
            this.notificationTypes.set(driver.notifications[j].id, driver.notifications[j]);
          }
        }
      }
    }
    if (run.results !== undefined) {
      for (var k = 0; k < run.results.length; k++) {
        this.categorizeResult(run.results[k]);
      }
    }
    if (run.invocations) {
      for (var h = 0; h < run.invocations.length; h++) {
        let invocation = run.invocations[h];
        if (invocation.toolExecutionNotifications) {
          for (var l = 0; l < invocation.toolExecutionNotifications.length; l++) {
            this.categorizeNotification(invocation.toolExecutionNotifications[l]);
          }
        }
      }
    }
  }
}