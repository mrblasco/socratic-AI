
SUBMIT_DIR := output/drafts

PDF_REPORT := $(SUBMIT_DIR)/main_report.pdf
PDF_ANONYM := $(SUBMIT_DIR)/main_report_anonym.pdf

DOCX_REPORT := $(PDF_REPORT:.pdf=.docx)

REPORTS := $(PDF_REPORT) $(PDF_ANONYM) $(DOCX_REPORT)

RMD_FILES := $(wildcard *.Rmd)

# Formats 

DOCX_FORMAT := bookdown::word_document2
PDF_FORMAT := bookdown::pdf_document2

# ---- Targets  ------------------------

all: $(PDF_REPORT)

$(SUBMIT_DIR):
	mkdir -p $@

$(SUBMIT_DIR)/%.pdf : %.Rmd $(RMD_FILES) _output.yml refs.bib $(SUBMIT_DIR)
	Rscript -e 'rmarkdown::render("$<", "$(PDF_FORMAT)", "$@")'

$(SUBMIT_DIR)/%.docx : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", "$(DOCX_FORMAT)", "$@")'

$(SUBMIT_DIR)/%_anonym.pdf : %.Rmd $(RMD_FILES) $(CONFIG)
	Rscript -e 'rmarkdown::render("$<", "$(PDF_FORMAT)", "$@", params = list(anonymous = TRUE))'

clean: 
	rm -f *.ttt *.log *.fff


# ----- Revision 

revision: journal_HSSC/Response_referees/round_2/rebutal_point_by_point.pdf

%.pdf : %.md
	pandoc $< --from markdown --to pdf -o $@
	open -a Skim $@


# Archive ---

pictures := assets/pictures/classrooms.pdf assets/pictures/experimental_design.pdf 

archive.zip: $(PDF_ANONYM:.pdf=.tex) $(PDF_ANONYM:.pdf=_files) $(pictures)
	cp $< main.tex 
	zip -r $@ main.tex $+ 

# Mardked up difference --- 

old.tex : 
	git show diff:main_report.tex

diff.tex : old.tex $(SUBMIT_DIR)/main_report.tex
	latexdiff $+ > $@

diff.pdf : diff.tex
	pdflatex $<

# --- 

view:
	open -a Skim $(PDF_REPORT)

