import { Component, ReactNode } from "react";
import { SarifData } from "../sarif/sarif-data-loader";
import { ResultItem } from "./result-item.component";

interface PropsType {
  dataLoader: SarifData
}

export class ResultList extends Component<PropsType, any, any> {
  public dataLoader: SarifData;

  constructor(props: PropsType) {
    super(props);
    this.dataLoader = props.dataLoader;
  }

  render(): ReactNode {
    let resultItems = this.dataLoader.results.map((res, idx) => {
      return <ResultItem
        dataLoader={this.dataLoader}
        result={res}
        index={idx}
        key={`result-item-${idx}`}
        ></ResultItem>
    });

    return (
      <div className="row">
        <div className="col-12">
          <div className="row">
            <div className="col-12">
            <h2>Results</h2>
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