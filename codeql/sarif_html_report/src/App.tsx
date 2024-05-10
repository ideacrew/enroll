import './App.css';
import 'bootstrap/dist/css/bootstrap.css';
import "bootstrap-icons/font/bootstrap-icons.css";
import { SarifData } from './sarif/sarif-data-loader';
import { Summary } from './components/summary.component';
import { ResultList } from './components/result-list.component'

function App() {
  let dataLoader = new SarifData();
  return (
    <div className="App">
      <Summary dataLoader={dataLoader}></Summary>
      <ResultList dataLoader={dataLoader}></ResultList>
    </div>
  );
}

export default App;
