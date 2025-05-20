# Inputs  ------------------------
CONFIG := _output.yml
RMD_FILES := $(wildcard *.Rmd)
PDF_REPORT := Submission/main_report.pdf

# Targets  ------------------------
all: $(PDF_REPORT) submission view clean

docx: main_report.docx

Submission/%.pdf : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<")'

%.docx : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

submission: Submission/cover_letter.pdf Submission/declaration.docx \
	Submission/acknowledgement.docx

Submission/cover_letter.pdf : Submission/cover_letter.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "linl::linl")'

Submission/declaration.docx : Submission/declaration.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

Submission/acknowledgement.docx : Submission/acknowledgement.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'


view: 
	open -a Skim $(PDF_REPORT)

clean: 
	rm -f *.ttt *.log *.fff
