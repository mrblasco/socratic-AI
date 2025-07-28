# Clean 
rm draft_diff/*.tex

# Old
git checkout main 
cp HSSC_Revised_Submission/main_report.tex draft_diff/1_old.tex

# New 
git checkout draft/hssc/rev-2 
cp output/drafts/main_report.tex draft_diff/2_new.tex

# Differences
latexdiff draft_diff/*.tex > draft_diff/main_diff.tex
pdflatex draft_diff/main_diff.tex
