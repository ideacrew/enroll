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

  const runTime = (backgroundRuntime + scenarioRuntime) / 1_000_000;
  if (isNaN(runTime)) {
    console.log('RUNTIME:', {
      uri,
      backgroundRuntime,
      scenarioRuntime,
      runTime,
    });
  }

  return {
    filePath: uri,
    runTime,
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

      let stepsRuntime = 0;
      if (steps === undefined) {
        // console.log('calculateBackgroundRuntime steps is undefined');
        stepsRuntime = 0;
      } else {
        stepsRuntime = calculateElementStepRuntime(steps);
      }

      const totalBackgroundRuntime = beforeRuntime + stepsRuntime;

      return totalBackgroundRuntime;
    })
    .reduce((total, runtime) => {
      return total + runtime;
    }, 0);

  // console.log('calculateBackgroundRuntime elementRuntime', elementRuntime);
  return elementRuntime;
};

const calculateScenarioRuntime = (elements: ScenarioElement[]): number => {
  const elementRuntime = elements
    .map(({ after, steps }) => {
      const afterRuntime = calculateStepRuntime(after);

      let stepsRuntime = 0;
      if (steps === undefined) {
        // console.log('calculateBackgroundRuntime steps is undefined');
        stepsRuntime = 0;
      } else {
        stepsRuntime = calculateElementStepRuntime(steps);
      }

      console.log({ afterRuntime, stepsRuntime });

      const totalBackgroundRuntime = afterRuntime + stepsRuntime;
      console.log({ totalBackgroundRuntime });
      return totalBackgroundRuntime;
    })
    .reduce((total, runtime) => {
      return total + runtime;
    }, 0);

  return elementRuntime;
};

const calculateElementStepRuntime = (steps: ElementStep[]): number => {
  // if (steps === undefined) {
  //   console.log('calculateElementStepRuntime steps is undefined');
  // }
  // console.log('HOW MANY STEPS?', steps.length);
  const stepRuntime = calculateStepRuntime(steps as BaseStep[]);
  // console.log({ stepRuntime });
  const afterRuntime = calculateStepRuntime(
    steps.map((step) => step.after).flat()
  );

  if (isNaN(stepRuntime) || isNaN(afterRuntime)) {
    console.log(
      '**********calculateElementStepRuntime stepRuntime**************',
      stepRuntime
    );
  }

  return stepRuntime + afterRuntime;
};

const calculateStepRuntime = (steps: BaseStep[]): number => {
  const stepRuntime = steps.reduce((total, step) => {
    const stepDuration = step.result.duration ?? 0;

    const accumulatedStepRuntime = total + stepDuration;

    return accumulatedStepRuntime;
  }, 0);

  if (isNaN(stepRuntime)) {
    console.log('calculateStepRuntime stepRuntime', steps);
  }

  return stepRuntime;
};
