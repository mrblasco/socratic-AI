# render rebuttal

SRCFILE=peer_review/2025-11-fourth-round/rebuttal.Rmd
Rscript -e "rmarkdown::render('$SRCFILE', \
    output_dir = 'docs', \
    output_format = 'bookdown::pdf_document2')"

