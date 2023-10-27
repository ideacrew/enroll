### Next Steps:
1. Finalize a template for documenting a false positive.
2. Add previously identified false positives to the CODESWEEP_FALSE_POSITIVES.MD file.
3. Add more information to [Real Security Issue](CODESWEEP_FALSE_POSITIVES_README.MD#real-security-issue) which could be helpful for developers to understand the process.
    1. Usually after the fix we will merge this into trunk after this PR passes 2 reviews before we QA this.
    2. In some cases, we might want to to QA this before we merge this into trunk.

##### Below is an example of how we can document a false positive:
1.
    1. Vulnerability: `CrossSiteRequestForgery`
    2. Severity: `Medium`
    3. Cause:
    4. False positive reason:
    5. Pull Request Link: https://github.com/ideacrew/enroll/pull/3126
2.
    1. Vulnerability: `Injection.SQL`
    2. Severity: `High`
    3. Cause:
    4. False positive reason:
    5. Pull Request Link: https://github.com/ideacrew/enroll/pull/3130
