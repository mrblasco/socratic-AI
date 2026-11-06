# ---- Config  ------------------------
CONFIG := _output.yml
BIB_FILE := refs.bib
MAIN := main.Rmd
RMD_FILES := $(MAIN) $(wildcard sections/*.Rmd)
STYLES := $(wildcard styles/*)

CSL_FILE := styles/hssc.csl
CSL_URL := https://gist.githubusercontent.com/sjgknight/6c4ae87761704bbbedf780fe71119f54/raw

FILTER_DIR := assets/lua-filters
FILTERS := $(FILTER_DIR)/scholarly-metadata.lua $(FILTER_DIR)/author-info-blocks.lua
LUA_URL := https://raw.githubusercontent.com/pandoc/lua-filters/master

REV ?= v5
PREV_REV ?=v4

SUBMIT_DIR := output
PDF_REPORT := $(SUBMIT_DIR)/main.pdf
PDF_ANONYM := $(SUBMIT_DIR)/main_anonym.pdf
DOC_REPORT := $(PDF_REPORT:.pdf=.docx)

CUR_TEX := $(PDF_REPORT:.pdf=.tex)

# Targets  ------------------------

draft: $(PDF_REPORT)

all: setup reports clean

setup: $(CSL_FILE) $(FILTERS)
	@mkdir -p $(SUBMIT_DIR) 
	@echo "Setup complete."

# Download missing style / filter files (only fetched if absent)
$(CSL_FILE):
	@mkdir -p $(dir $@)
	@echo "Downloading $@ ..."
	@curl -fsSL -o $@ $(CSL_URL)

$(FILTER_DIR)/%.lua:
	@mkdir -p $(FILTER_DIR)
	@echo "Downloading $@ ..."
	@curl -fsSL -o $@ $(LUA_URL)/$*/$*.lua

# ---- reports ----

reports: $(PDF_REPORT) $(PDF_ANONYM) $(DOC_REPORT)

$(PDF_REPORT): $(RMD_FILES) $(CONFIG) $(BIB_FILE) $(STYLES) $(FILTERS)
	@mkdir -p $(SUBMIT_DIR)
	@Rscript -e 'rmarkdown::render("$(MAIN)", output_file = "$@", output_format = "bookdown::pdf_document2")'

$(PDF_ANONYM): $(RMD_FILES) $(CONFIG) $(BIB_FILE) $(STYLES) $(FILTERS)
	@mkdir -p $(SUBMIT_DIR)
	@Rscript -e 'rmarkdown::render("$(MAIN)", output_file = "$@", output_format = "bookdown::pdf_document2", params = list(anonymous = TRUE))'

$(DOC_REPORT): $(RMD_FILES) $(CONFIG) $(BIB_FILE) $(STYLES) $(FILTERS)
	@mkdir -p $(SUBMIT_DIR)
	@Rscript -e 'rmarkdown::render("$(MAIN)", output_file = "$@", output_format = "bookdown::word_document2")'

html: $(SUBMIT_DIR)/main.html

$(SUBMIT_DIR)/main.html: $(RMD_FILES) $(CONFIG) $(BIB_FILE) $(STYLES) $(FILTERS)
	@mkdir -p $(SUBMIT_DIR)
	@Rscript -e 'rmarkdown::render("$(MAIN)", output_file = "$@", output_format = "distill::distill_article")'

# --- Archive ---

pictures := assets/pictures/classrooms.pdf assets/pictures/experimental_design.pdf 

archive.zip: $(PDF_ANONYM:.pdf=.tex) $(PDF_ANONYM:.pdf=_files) $(pictures)
	cp $< main.tex 
	zip -r $@ main.tex $+ 

# --- Mardked up difference --- 

#OLD := ./_output/v3/HSSC_Revised_Submission/main_report.tex 

diff : $(SUBMIT_DIR)/main_diff.pdf

PREV_TAG := rev4submitted-output

old.tex: 
	@git show $(PREV_TAG):$(SUBMIT_DIR)/main_report.tex > $@

diff.tex: old.tex $(SUBMIT_DIR)/main.tex
	@latexdiff \
	--config="PICTUREENV=(?:picture|DIFnomarkup|align)[\w\d*@]*"  \
	--append-safecmd="toprule,midrule,bottomrule" $+ > $@

$(SUBMIT_DIR)/main_diff.pdf: diff.tex
	pdflatex diff.tex
	pdflatex diff.tex
	mv diff.pdf $@

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
	@open $<

$(SUBMIT_DIR)/rebuttal.pdf: peer_review/2026-06-fifth-round/rebuttal.pdf
	cp $< $@

peer_review/2026-06-fifth-round/rebuttal.pdf: peer_review/2026-06-fifth-round/rebuttal.Rmd
	@Rscript -e 'rmarkdown::render("$<", output_format = "pdf_document")'
	@open -a Skim peer_review/2026-06-fifth-round/rebuttal.pdf

# ----- 

bib:
	open -a Bibdesk ./refs.bib

view:
	open -a Skim $(PDF_REPORT)

clean: 
	@rm -f *.ttt *.log *.fff
	@rm diff.*
