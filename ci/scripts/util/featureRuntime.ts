import {
  BackgroundElement,
  ScenarioElement,
  CucumberFeature,
  BaseStep,
  FileWithRuntime,
  ElementStep,
} from '../models';

export const featureRuntime = (feature: CucumberFeature): FileWithRuntime => {
  const { uri, elements } = feature;

  const scenarioElements: ScenarioElement[] = elements.filter(isScenario);
  const backgroundElements: BackgroundElement[] = elements.filter(isBackground);

  const backgroundRuntime = calculateBackgroundRuntime(backgroundElements);
  const scenarioRuntime = calculateScenarioRuntime(scenarioElements);

  return {
    filePath: feature.uri,
    runTime: (backgroundRuntime + scenarioRuntime) / 1_000_000,
  };
};

const isScenario = (
  element: BackgroundElement | ScenarioElement
): element is ScenarioElement => (element as ScenarioElement).id !== undefined;

const isBackground = (
  element: BackgroundElement | ScenarioElement
): element is BackgroundElement =>
  (element as BackgroundElement).before !== undefined;

const calculateBackgroundRuntime = (elements: BackgroundElement[]): number => {
  const elementRuntime = elements
    .map(({ before, steps }) => {
      const beforeRuntime = calculateStepRuntime(before);
      const stepsRuntime = calculateElementStepRuntime(steps);

      const totalBackgroundRuntime = beforeRuntime + stepsRuntime;

      return totalBackgroundRuntime;
    })
    .reduce((total, runtime) => {
      return total + runtime;
    }, 0);

  return elementRuntime;
};

const calculateScenarioRuntime = (elements: ScenarioElement[]): number => {
  const elementRuntime = elements
    .map(({ after, steps }) => {
      const afterRuntime = calculateStepRuntime(after);
      const stepsRuntime = calculateElementStepRuntime(steps);

      const totalBackgroundRuntime = afterRuntime + stepsRuntime;

      return totalBackgroundRuntime;
    })
    .reduce((total, runtime) => {
      return total + runtime;
    }, 0);

  return elementRuntime;
};

const calculateElementStepRuntime = (steps: ElementStep[]): number => {
  const stepRuntime = calculateStepRuntime(steps as BaseStep[]);

  const afterRuntime = calculateStepRuntime(
    steps.map((step) => step.after).flat()
  );

  return stepRuntime + afterRuntime;
};

const calculateStepRuntime = (steps: BaseStep[]): number => {
  return steps.reduce((total, step) => {
    return total + step.result.duration;
  }, 0);
};
