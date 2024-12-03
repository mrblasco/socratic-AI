
# Inputs  ------------------------
CONFIG := _output.yml
MD_FILES := $(wildcard *.Rmd)

# Targets  ------------------------
all: report view clean

report: main_report.pdf
docx: main_report.docx

%.pdf : %.Rmd $(MD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::pdf_document2")'

%.docx : %.Rmd $(MD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

view: 
	open -a Skim main_report.pdf

clean: 
	rm -f *.ttt *.log *.fff
