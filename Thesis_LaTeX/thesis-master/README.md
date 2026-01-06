# A template for BSc / MSc theses

Document template suitable for use as a LaTeX master-file for bachelor's /
master's thesis in University of Turku Department of Computing.

Compatible with: Overleaf, pdfLaTeX, LuaLaTeX, XeLaTeX, LyX, latexmk.
The template is configured to use the prebuilt TeXLive image available via
[thesis/builder](https://gitlab.utu.fi/tech/soft/thesis/builder).

## Documentation

Online documentation available at
**<https://tech.utugit.fi/soft/thesis/doc/doc/>**.

Visit the [generated preview page](https://ttweb.utugit.fi/thesis)
for a live demo of the rendered document. When compiling your own
thesis using GitLab CI/CD, considering using the [more lightweight
CI/CD configuration](./.gitlab-ci-simple.yml) to speed up the compilation.

## Bugs / improvements

Merge requests and bug reports are welcome - if you find an issue,
[please report to us](issues/new). There is also [another issue tracker
for the documentation](https://gitlab.utu.fi/tech/soft/thesis/doc/-/issues/new).

## Version history


* 2019/12/20: Switched to pdf/a a-2b, list of acronyms with nomencl,
fix tests, switch to a custom Dockerfile, add support+example demonstrating minted
* 2019/05/28: Fixed app. page count for documents with multipage floating
content in appendices, adjustments to options and font handling, documentation, options
for handling long urls in the bibliography, removed unnecessary deps titlecaps & sverb
* 2019/05/02: PDF/A-1b support (via pdfx), moved chead to cfoot, updated UTU logos
* 2018/10/06: Got rid of startappendices and startpages. various fixes. cleanups
* 2018/10/02: Removed redundant tutkielma.tex, fixed issues with appendices,
small caps, added an option to enable the truetype times new roman font
* 2018/08/29: Switch to document classes, xelatex, biblatex, and additional TeX scripting.
Jari-Matti Mäkelä (jmjmak@utu.fi)
* 2017/10/01 - 2016/9/22 additions marked "JH:", modified for use in tex.soft.utu.fi,
Johannes Holvitie (jjholv@utu.fi)
* 2015/09/05: Version 1.3, Sami Nuuttila (samnuutt@utu.fi)
