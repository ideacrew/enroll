import './App.css';
import 'bootstrap/dist/css/bootstrap.css';
import "bootstrap-icons/font/bootstrap-icons.css";
import { SarifData } from './sarif/sarif-data-loader';
import { Summary } from './components/summary.component';
import { ResultList } from './components/result-list.component'
import { NotificationList } from './components/notification-list.component';
import { Component, ReactNode } from "react";

type StateType = {
  dataLoader: SarifData;
}

export class App extends Component<any, StateType, any> {
  constructor(props: any) {
    super(props);
    this.state = {
      dataLoader: new SarifData()
    };
  }

  render(): ReactNode {
    return (
      <div className="App">
        <Summary dataLoader={this.state.dataLoader}></Summary>
        <ResultList dataLoader={this.state.dataLoader}></ResultList>
        { this.state.dataLoader.notifications.length > 0 &&
          <NotificationList dataLoader={this.state.dataLoader}></NotificationList>
        }
      </div>
    );
  };
}


export default App;
