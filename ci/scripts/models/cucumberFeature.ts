export interface CucumberFeature {
  uri: string; // file path
  id: string;
  keyword: 'Feature';
  name: string;
  description: string;
  line: number;
  elements: Array<ScenarioElement | BackgroundElement>;
}

export interface BackgroundElement {
  keyword: 'Background';
  type: 'background';
  before: BaseStep[];
  name: string;
  description: string;
  line: number;
  steps?: ElementStep[];
}

export interface ScenarioElement {
  id: string;
  keyword: string;
  type: 'scenario';
  before?: BaseStep[];
  after: BaseStep[];
  name: string;
  description: string;
  line: number;
  steps?: ElementStep[];
  comments?: Comment[];
}

interface Comment {
  value: string;
  line: number;
}

export interface ElementStep extends BaseStep {
  keyword: string;
  name: string;
  line: number;
  after: BaseStep[];
}

export interface BaseStep {
  match: {
    location: string;
  };
  result: {
    status: string;
    duration?: number; // in nanoseconds
  };
}
