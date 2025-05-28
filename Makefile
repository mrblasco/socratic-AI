# Inputs  ------------------------
CONFIG := _output.yml
RMD_FILES := $(wildcard *.Rmd)
SUBMIT_DIR := Submission

PDF_REPORT := $(SUBMIT_DIR)/main_report.pdf
DOC_REPORT := $(PDF_REPORT:.pdf=.docx)

# Targets  ------------------------
all: $(PDF_REPORT) $(DOC_REPORT) review submission view clean


$(SUBMIT_DIR)/%.pdf : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_file = "$@")'

$(SUBMIT_DIR)/%.docx : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2", output_file = "$@")'

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

review: $(SUBMIT_DIR)/rebuttal_point_by_point.pdf $(SUBMIT_DIR)/rebuttal_point_by_point.docx
	open $<

$(SUBMIT_DIR)/%.docx : Reviews/round_1/%.md
	pandoc --from markdown --to docx -C $< -o $@

$(SUBMIT_DIR)/%.pdf : Reviews/round_1/%.md
	pandoc --pdf-engine xelatex --from markdown --to pdf -C $< -o $@

view:
	open -a Skim $(PDF_REPORT)

clean: 
	rm -f *.ttt *.log *.fff
