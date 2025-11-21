# ---- Config  ------------------------
CONFIG := _output.yml
BIB_FILE := refs.bib
RMD_FILES := $(wildcard *.Rmd)

SUBMIT_DIR := _output/v4

PDF_REPORT := $(SUBMIT_DIR)/main_report.pdf
PDF_ANONYM := $(SUBMIT_DIR)/main_report_anonym.pdf
DOC_REPORT := $(PDF_REPORT:.pdf=.docx)

# Targets  ------------------------

draft: $(PDF_REPORT)

all: setup reports clean

setup: 
	@mkdir -p $(SUBMIT_DIR) 
	@echo "Setup complete."

# ---- reports ----

reports: $(PDF_REPORT) $(PDF_ANONYM) $(DOC_REPORT)

$(SUBMIT_DIR)/%.pdf : %.Rmd $(RMD_FILES) $(CONFIG) $(BIB_FILE)
	Rscript -e 'rmarkdown::render("$<", output_file = "$@", output_format="bookdown::pdf_document2")'

$(SUBMIT_DIR)/%.docx : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2", output_file = "$@")'

$(SUBMIT_DIR)/%_anonym.pdf : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", output_file = "$@", params = list(anonymous = TRUE))'

# --- Archive ---

pictures := assets/pictures/classrooms.pdf assets/pictures/experimental_design.pdf 

archive.zip: $(PDF_ANONYM:.pdf=.tex) $(PDF_ANONYM:.pdf=_files) $(pictures)
	cp $< main.tex 
	zip -r $@ main.tex $+ 

# --- Mardked up difference --- 

diff: $(SUBMIT_DIR)/diff.pdf

OLD := ./_output/v3/HSSC_Revised_Submission/main_report.tex 

diff.tex : $(OLD) $(PDF_REPORT:.pdf=.tex) 
	@latexdiff $+ > $@

$(SUBMIT_DIR)/diff.pdf : diff.tex
	@pdflatex $< && cp diff.pdf $@


# ---- Submission Materials ----

submission: \
	$(SUBMIT_DIR)/cover_letter.pdf \
	$(SUBMIT_DIR)/declaration.docx \
	$(SUBMIT_DIR)/acknowledgement.docx

$(SUBMIT_DIR)/cover_letter.pdf : $(SUBMIT_DIR)/cover_letter.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "linl::linl")'

$(SUBMIT_DIR)/declaration.docx : $(SUBMIT_DIR)/declaration.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

$(SUBMIT_DIR)/acknowledgement.docx : $(SUBMIT_DIR)/acknowledgement.Rmd
	Rscript -e 'rmarkdown::render("$<", output_format = "bookdown::word_document2")'

# ---- Review ----

rebuttal: rebuttal.pdf
	@open -a Skim $<

rebuttal.pdf : peer_review/2025-11-fourth-round/rebuttal.md
	@pandoc $< -C -o $@ --bibliography=References/refs.bib


review: $(SUBMIT_DIR)/rebuttal.pdf

$(SUBMIT_DIR)/%.pdf : peer_review/2025-11-fourth-round/%.md
	@pandoc --from markdown --to pdf -C $< -o $@
	@open $@

# ----- 

bib:
	open -a Bibdesk ./refs.bib

view:
	open -a Skim $(PDF_REPORT)

clean: 
	@rm -f *.ttt *.log *.fff
	@rm diff.*
