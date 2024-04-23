import { Component, ReactNode } from "react";
import { SarifData } from "../sarif/sarif-data-loader";

interface PropsType {
  dataLoader: SarifData
}

export class Summary extends Component<PropsType, any, any> {
  public dataLoader: SarifData;

  constructor(props: PropsType) {
    super(props);
    this.dataLoader = props.dataLoader;
  }

  getTotal(): number {
    return (
      this.dataLoader.errors +
      this.dataLoader.warnings +
      this.dataLoader.notes +
      this.dataLoader.infos
    );
  }

  render(): ReactNode {
    return (
      <div className="row">
        <div className="col-12">
          <div className="row">
            <div className="col-12">
              <h2>Summary</h2>
            </div>
          </div>
          <div className="row">
            <div className="col-3">
              <table className="table table-responsive table-bordered">
                <thead className="table-light">
                  <tr>
                    <th scope="col">Type</th>
                    <th scope="col">Count</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <th>Error</th>
                    <td className="numeric-totals">{this.dataLoader.errors}</td>
                  </tr>
                  <tr>
                    <th>Warning</th>
                    <td className="numeric-totals">{this.dataLoader.warnings}</td>
                  </tr>
                  <tr>
                    <th>Note</th>
                    <td className="numeric-totals">{this.dataLoader.notes}</td>
                  </tr>
                  <tr>
                    <th>Info</th>
                    <td className="numeric-totals">{this.dataLoader.infos}</td>
                  </tr>
                </tbody>
                <tfoot>
                  <tr>
                    <th>Total</th>
                    <th className="numeric-totals">{this.getTotal()}</th>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        </div>
      </div>
    );
  }
}