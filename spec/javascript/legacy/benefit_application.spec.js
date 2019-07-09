import { calculateEmployeeCosts, calculateEmployerContributions } from 'legacy/benefit_application';

describe("legacy/benefit_application", () => {
  test("exports the global methods", () => {
    expect(calculateEmployeeCosts).not.toBe(null);
    expect(calculateEmployerContributions).not.toBe(null);
  });
});