import { Component, ReactNode } from "react";
import { SarifData } from "../sarif/sarif-data-loader";
import { NotificationItem } from "./notification-item.component"

interface PropsType {
  dataLoader: SarifData
}

export class NotificationList extends Component<PropsType, any, any> {
  public dataLoader: SarifData;

  constructor(props: PropsType) {
    super(props);
    this.dataLoader = props.dataLoader;
  }

  render(): ReactNode {
    let resultItems = this.dataLoader.notifications.map((res, idx) => {
      return <NotificationItem
        dataLoader={this.dataLoader}
        result={res}
        index={idx}
        key={`notification-item-${idx}`}
        ></NotificationItem>
    });

    return (
      <div className="row">
        <div className="col-12">
          <div className="row">
            <div className="col-12">
            <h2>Notifications</h2>
            </div>
          </div>
          <div className="row">
            <div className="col-12">
              <table className="table">
                <thead>
                  <tr>
                    <th>Issue</th>
                    <th>Location</th>
                  </tr>
                </thead>
                <tbody>
                  {resultItems}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    );
  }
}