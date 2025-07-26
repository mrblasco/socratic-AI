# Outputs
OUTPUT_DIR := output/drafts
PDF_REPORT := $(OUTPUT_DIR)/main_report.pdf
DOCX_REPORT := $(PDF_REPORT:.pdf=.docx)

# Inputs
RMD_FILES := $(wildcard *.Rmd)

# Formats
DOCX_FORMAT := bookdown::word_document2
PDF_FORMAT := bookdown::pdf_document2

COMMIT_MSG ?= "Update"

# ---- Targets  ------------------------

all: $(PDF_REPORT) $(DOCX_REPORT)

$(OUTPUT_DIR):
	mkdir -p $@

$(OUTPUT_DIR)/%.pdf : %.Rmd $(RMD_FILES) _output.yml refs.bib $(OUTPUT_DIR)
	Rscript -e 'rmarkdown::render("$<", "$(PDF_FORMAT)", "$@")'

$(OUTPUT_DIR)/%.docx : %.Rmd $(RMD_FILES) _output.yml refs.bib $(OUTPUT_DIR)
	Rscript -e 'rmarkdown::render("$<", "$(DOCX_FORMAT)", "$@")'

clean: 
	rm -f *.ttt *.log *.fff

view:
	open -a Skim $(PDF_REPORT)

commit: 
	@git add . && git commit -m "$(COMMIT_MSG)"
	@echo "Committed changes with message: $(COMMIT_MSG)"


# ----- Revision 

revision: $(OUTPUT_DIR)/_rebuttal_to_reviewers_rev2.pdf

$(OUTPUT_DIR)/%.pdf : docs/%.md
	pandoc $< --from markdown --to pdf -C -o $@

# Archive ---

pictures := assets/pictures/classrooms.pdf assets/pictures/experimental_design.pdf 

archive.zip: $(PDF_ANONYM:.pdf=.tex) $(PDF_ANONYM:.pdf=_files) $(pictures)
	cp $< main.tex 
	zip -r $@ main.tex $+ 

# Mardked up difference --- 

show_diffs: old.tex main.tex
	latexdiff $+ > diff.tex && pdflatex diff.tex

old.tex : 
	git show diff:main_report.tex

diff.tex : old.tex $(SUBMIT_DIR)/main_report.tex
	latexdiff $+ > $@

diff.pdf : diff.tex
	pdflatex $<

# --- 

