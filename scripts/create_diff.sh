OLDFILE=./_output/v3/HSSC_Revised_Submission/main_report.tex 

latexdiff --flatten "$OLDFILE" docs/main_report.tex > diff.tex

pdflatex diff.tex

