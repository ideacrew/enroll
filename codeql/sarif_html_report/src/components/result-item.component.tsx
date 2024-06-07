import { Component, ReactNode, Fragment } from "react";
import { Result, ReportingDescriptor } from "sarif";
import { SarifData } from "../sarif/sarif-data-loader";

interface PropsType {
  result: Result;
  dataLoader: SarifData
  index: number;
}

interface StateType {
  expanded: boolean;
}

export class ResultItem extends Component<PropsType, StateType, any> {
  public dataLoader: SarifData;
  public result: Result;
  public index: number;
  public rule: ReportingDescriptor;

  public toggleItem = () => {
    this.setState((s) => {
      return {
        expanded: !s.expanded
      };
    })
  };

  constructor(props: PropsType) {
    super(props);
    this.dataLoader = props.dataLoader;
    this.result = props.result;
    this.index = props.index;
    this.rule = this.dataLoader.rules.get(this.result.ruleId!)!;
    this.state = {
      expanded: false
    };
  }

  private extractSnippet() {
    let locations = this.result.locations;
    if (locations) {
      let location = locations[0];
      if (location) {
        let snip = location.physicalLocation?.contextRegion?.snippet;
        if (snip && snip.text) {
          return snip.text;
        }
      }
    }
    return "";
  }

  private extractLocation() {
    let locations = this.result.locations;
    if (locations) {
      let location = locations[0];
      let uri = location.physicalLocation?.artifactLocation?.uri;
      let lineNumber = location.physicalLocation?.region?.startLine;
      if (uri && lineNumber) {
        return `${uri}:${lineNumber}`;
      }
    }
    return "";
  }

  getExpansionClass() {
    if (this.state.expanded) {
      return "show";
    }
    return "hidden";
  }

  getArrowClass() {
    if (this.state.expanded) {
      return "bi bi-arrow-up-circle h3 result-item-arrow";
    }
    return "bi bi-arrow-down-circle h3 result-item-arrow";
  }

  getDescription() {
    let ignoreString = "";
    if (this.dataLoader.ignores.length > 0) {
      if (this.result.partialFingerprints) {
        const pllHash = this.result.partialFingerprints.primaryLocationLineHash;
        const plStartColumnFingerprint = this.result.partialFingerprints.primaryLocationStartColumnFingerprint;
        const matchingIgnores = this.dataLoader.ignores.filter((entry) => {
          return (pllHash === entry.fingerprint.primaryLocationLineHash) &&
            (plStartColumnFingerprint.toString() === entry.fingerprint.primaryLocationStartColumnFingerprint.toString()) &&
            (this.result.ruleId === entry.ruleId);
        });
        if (matchingIgnores.length > 0) {
          ignoreString = "[IGNORED] ";
        }
      }
    } 
    return ignoreString + this.rule.shortDescription?.text;
  }

  render(): ReactNode {
    return (
      <Fragment>
        <tr key={`result-item-table-row-${this.index}`} onClick={this.toggleItem}>
          <td>{this.getDescription()}</td>
          <td>{this.extractLocation()}<i className={this.getArrowClass()}></i></td>
        </tr>
        <tr key={`result-item-table-body-${this.index}`} className={this.getExpansionClass()}>
          <td colSpan={2}>
            <h4>Details</h4>
            <pre>
              {this.result.message.text}
            </pre>
            <h4>Code</h4>
            <pre>
              {this.extractSnippet()}
            </pre>
          </td>
        </tr>
      </Fragment>
    );
  }
}