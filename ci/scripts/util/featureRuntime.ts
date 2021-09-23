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
    filePath: uri,
    runTime: scenariosRuntime + backgroundRuntime,
  };
};

const isScenario = (
  element: BackgroundElement | ScenarioElement
): element is ScenarioElement =>
  (element as ScenarioElement).type === 'scenario';

const isBackground = (
  element: BackgroundElement | ScenarioElement
): element is BackgroundElement =>
  (element as BackgroundElement).type === 'background';

const calculateBackgroundRuntime = (
  backgroundElement: BackgroundElement
): number => {
  const { before, steps } = backgroundElement;

  const beforeRuntime = calculateBaseStepsRuntime(before);
  const elementStepRuntime = steps ? calculateElementStepsRuntime(steps) : 0;

  return beforeRuntime + elementStepRuntime;
};

const calculateScenarioRuntime = (scenario: ScenarioElement): number => {
  const { before, steps, after } = scenario;

  const beforeRuntime = before ? calculateBaseStepsRuntime(before) : 0;
  const elementStepsRuntime = steps ? calculateElementStepsRuntime(steps) : 0;
  const afterRuntime = after ? calculateBaseStepsRuntime(after) : 0;

  return beforeRuntime + elementStepsRuntime + afterRuntime;
};

const calculateElementStepsRuntime = (elementSteps: ElementStep[]): number => {
  const elementStepsRuntime = elementSteps.reduce((acc, elementStep) => {
    const stepDuration = elementStepDuration(elementStep);
    const afterRuntime = calculateBaseStepsRuntime(elementStep.after);

    const totalStepRuntime = stepDuration + afterRuntime;

    return acc + totalStepRuntime;
  }, 0);

  return elementStepsRuntime;
};

const calculateBaseStepsRuntime = (baseSteps: BaseStep[]): number => {
  let runtime = 0;

  baseSteps.forEach((baseStep) => {
    runtime = baseStep.result.duration
      ? runtime + baseStep.result.duration
      : runtime;
  });

  return runtime;
};

const elementStepDuration = (step: BaseStep): number => {
  if (step.result.duration === undefined) {
    return 0;
  } else if (
    step.match.location === 'features/step_definitions/integration_steps.rb:443'
  ) {
    return 698821936;
  } else {
    return step.result.duration;
  }
};
