import './App.css';
import 'bootstrap/dist/css/bootstrap.css';
import "bootstrap-icons/font/bootstrap-icons.css";
import { SarifData } from './sarif/sarif-data-loader';
import { Summary } from './components/summary.component';
import { ResultList } from './components/result-list.component'
import { NotificationList } from './components/notification-list.component';

function App() {
  let dataLoader = new SarifData();
  return (
    <div className="App">
      <Summary dataLoader={dataLoader}></Summary>
      <ResultList dataLoader={dataLoader}></ResultList>
      { dataLoader.notifications.length > 0 &&
        <NotificationList dataLoader={dataLoader}></NotificationList>
      }
    </div>
  );
}

export default App;
