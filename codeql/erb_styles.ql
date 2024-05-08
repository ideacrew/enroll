/**
 * @name Inline Styles in ERB template.
 * @kind problem
 * @id ideacrew/erb-styles
 * @problem.severity warning
 * @precision medium
*/

import codeql.ruby.AST

predicate hasInlineStyles(ErbToken et) {
  et.toString().indexOf("style=") > 0 
}

predicate hasStylesTag(ErbToken et) {
  et.toString().indexOf("style") > 0 and
    et.toString().indexOf("<") > 0 and
    et.toString().indexOf("style") > et.toString().indexOf("<") and
    et.toString().indexOf("style") != et.toString().indexOf("stylesheet")
}

predicate isErbHtml(File f) {
  f.getExtension() = "erb" and
    f.getStem().indexOf(".html") > 0
}

from File f, ErbToken et
where isErbHtml(f) and f.getRelativePath() = et.getLocation().getFile().getRelativePath() and (hasStylesTag(et) or hasInlineStyles(et))
select et.getLocation(), "has inline styles"
