import { Component, ReactNode, Fragment } from "react";
import { Result, Notification, ReportingDescriptor } from "sarif";
import { SarifData } from "../sarif/sarif-data-loader";

interface PropsType {
  result: Result;
  dataLoader: SarifData
  index: number;
}

interface StateType {
  expanded: boolean;
}

export class NotificationItem extends Component<PropsType, StateType, any> {
  public dataLoader: SarifData;
  public notification: Notification;
  public index: number;
  public notificationType: ReportingDescriptor;

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
    this.notification = props.result;
    this.index = props.index;
    this.notificationType = this.dataLoader.notificationTypes.get(this.notification.descriptor?.id!)!;
    this.state = {
      expanded: false
    };
  }

  private extractSnippet() {
    let locations = this.notification.locations;
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
    let locations = this.notification.locations;
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

  render(): ReactNode {
    return (
      <Fragment>
        <tr key={`result-item-table-row-${this.index}`} onClick={this.toggleItem}>
          <td>{this.notificationType.shortDescription?.text}</td>
          <td>{this.extractLocation()}<i className={this.getArrowClass()}></i></td>
        </tr>
        <tr key={`result-item-table-body-${this.index}`} className={this.getExpansionClass()}>
          <td colSpan={2}>
            <h4>Details</h4>
            <pre>
              {this.notification.message.text}
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