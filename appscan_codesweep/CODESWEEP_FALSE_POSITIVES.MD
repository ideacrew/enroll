### Next Steps:
1. Finalize a template for documenting a false positive.
2. Add previously identified false positives to the CODESWEEP_FALSE_POSITIVES.MD file. (And share it with Desire)
3. Add more information to [Real Security Issue](CODESWEEP_FALSE_POSITIVES_README.MD#real-security-issue) which could be helpful for developers to understand the process.
    1. Usually after the fix we will merge this into trunk after this PR passes 2 reviews before we QA this.
    2. In some cases, we might want to to QA this before we merge this into trunk.

##### Below is an example of how we can document a false positive:
1.
    1. Vulnerability: `CrossSiteRequestForgery`
    2. Severity: `Medium`
    3. Cause: Code includes an expression with the `match` keyword.  The AppScan heuristic for flagging default, insecure routing settings looks for expressions of the form `match =>`.
    4. False positive reasons:
        1. It seems to be unaware or not configured for the fact that the code of the form `$match =>` is frequently used in MongoDB queries.
        2. It doesn't verify that the expression in question is in a file or code block that actually controls Rails routing settings, such as `config/routes.rb`. The code it is flagging isn't in a routing configuration file and has nothing to do with routing. 
    5. Approved Cases:
        1. PR: https://github.com/ideacrew/enroll/pull/3126, file: app/models/queries/ivl_sep_events.rb

2.
    1. Vulnerability: `Injection.SQL`
    2. Severity: `High`
    3. Cause: Code includes an expression with the `where` keyword.
    4. False positive reasons:
        1. There is no user input being sent to the `.where` query: `.where(:"applicants.is_ia_eligible" => true)`
        2. The only parameter based on user input is already cast to an integer: `assistance_year = ENV['assistance_year'].to_i`
        3. The query is called in a script that is run manually and internally.
    5. Approved Cases:
        1. PR: https://github.com/ideacrew/enroll/pull/3130, file: script/export_rrv_families.rb
