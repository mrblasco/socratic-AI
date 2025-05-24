# Inputs  ------------------------
CONFIG := _output.yml
RMD_FILES := $(wildcard *.Rmd)
SUBMIT_DIR := Submission
PDF_REPORT := $(SUBMIT_DIR)/main_report.pdf

# Targets  ------------------------
all: $(PDF_REPORT) submission view clean

docx: main_report.docx

$(SUBMIT_DIR)/%.pdf : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_file = "$@")'

%.docx : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

# Submission ----

submission: $(SUBMIT_DIR)/cover_letter.pdf $(SUBMIT_DIR)/declaration.docx \
	$(SUBMIT_DIR)/acknowledgement.docx

$(SUBMIT_DIR)/cover_letter.pdf : $(SUBMIT_DIR)/cover_letter.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "linl::linl")'

$(SUBMIT_DIR)/declaration.docx : $(SUBMIT_DIR)/declaration.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

$(SUBMIT_DIR)/acknowledgement.docx : $(SUBMIT_DIR)/acknowledgement.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

# Review ----

review: $(SUBMIT_DIR)/rebuttal_point_by_point.docx

$(SUBMIT_DIR)/%.docx : Reviews/round_1/%.md
	pandoc --from markdown --to docx -C $< -o $@

view:
	open -a Skim $(PDF_REPORT)

clean: 
	rm -f *.ttt *.log *.fff
