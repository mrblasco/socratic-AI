
# Inputs  ------------------------
CONFIG := _output.yml
RMD_FILES := $(wildcard *.Rmd)

# Targets  ------------------------
all: report other view clean

other: cover_letter.pdf declaration.docx acknowledgement.docx
report: main_report.pdf
docx: main_report.docx

%.pdf : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<")'

%.docx : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

cover_letter.pdf : cover_letter.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "linl::linl")'

declaration.docx : declaration.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

acknowledgement.docx : acknowledgement.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'


view: 
	open -a Skim main_report.pdf

clean: 
	rm -f *.ttt *.log *.fff
