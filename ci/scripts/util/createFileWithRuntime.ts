import {
  CucumberFeature,
  ScenarioElement,
  isScenario,
  BackgroundElement,
  isBackground,
  calculateScenarioRuntime,
  calculateBackgroundRuntime,
} from 'cucumber-report-analyzer';
import { FileWithRuntime } from 'split-config-generator';

export const createFileWithRuntime = (
  feature: CucumberFeature
): FileWithRuntime => {
  const scenarioElements: ScenarioElement[] =
    feature.elements.filter(isScenario);

  const backgroundElements: BackgroundElement[] =
    feature.elements.filter(isBackground);

  const scenarioElementsRuntimes: number[] = scenarioElements.map(
    calculateScenarioRuntime
  );
  const backgroundElementsRuntimes: number[] = backgroundElements.map(
    calculateBackgroundRuntime
  );

  const scenariosRuntime = scenarioElementsRuntimes.reduce(
    (acc, curr) => acc + curr,
    0
  );

  const backgroundRuntime = backgroundElementsRuntimes.reduce(
    (acc, curr) => acc + curr,
    0
  );

  return {
    filePath: feature.uri,
    runtime: scenariosRuntime + backgroundRuntime,
  };
};
