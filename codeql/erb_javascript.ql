/**
 * @name Inline JavaScript in ERB template.
 * @kind problem
 * @id ideacrew/erb-javascript
 * @problem.severity warning
 * @precision medium
*/

import codeql.ruby.AST

predicate hasJS(ErbToken et) {
  et.toString().indexOf("script") > 0 and
    et.toString().indexOf("<") > 0 and
    et.toString().indexOf("script") > et.toString().indexOf("<")
}

predicate isErbHtml(File f) {
  f.getExtension() = "erb" and
    f.getStem().indexOf(".html") > 0
}

from File f, ErbToken et
where isErbHtml(f) and f.getRelativePath() = et.getLocation().getFile().getRelativePath() and hasJS(et)
select et.getLocation(), "has inline javascript"
