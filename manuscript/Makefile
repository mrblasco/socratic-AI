PDF := output/main_report.pdf
HTML := output/html/main_report.html
FILES := main_report.Rmd $(wildcard *)

FILTER_DIR := assets/lua-filters
FILTERS := $(FILTER_DIR)/scholarly-metadata.lua \
           $(FILTER_DIR)/author-info-blocks.lua


all: 
	@echo "html or pdf"

pdf: $(FILTERS) $(PDF)
html: $(FILTERS) $(HTML)


$(PDF): $(FILES)
	@echo "Rendering $@ ..."
	@Rscript -e 'rmarkdown::render("$<", output_dir = "$(dir $@)", output_format = "bookdown::pdf_document2")'

$(HTML): $(FILES)
	@echo "Rendering $@ ..."
	@Rscript -e 'rmarkdown::render("$<", output_dir = "$(dir $@)", output_format = "distill::distill_article")'

clean:
	rm -f $(PDF) $(HTML)

view: 
	@open -a Skim $(PDF)


$(FILTER_DIR)/%.lua:
	@mkdir -p $(FILTER_DIR)
	@echo "Downloading $@ ..."
	@case "$*" in \
		scholarly-metadata) \
			wget -O $@ https://raw.githubusercontent.com/pandoc/lua-filters/master/scholarly-metadata/scholarly-metadata.lua ;; \
		author-info-blocks) \
			wget -O $@ https://raw.githubusercontent.com/pandoc/lua-filters/master/author-info-blocks/author-info-blocks.lua ;; \
	esac