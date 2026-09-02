PDF := output/main_report.pdf
HTML := output/html/main_report.html
FILES := main_report.Rmd $(wildcard *)

all: 
	@echo "html or pdf"

pdf: $(PDF)
html: $(HTML)

$(PDF): $(FILES)
	@echo "Rendering $@ ..."
	@Rscript -e 'rmarkdown::render("$<", output_dir = "$(dir $@)", output_format = "bookdown::pdf_document2")'

$(HTML): $(FILES)
	@echo "Rendering $@ ..."
	@Rscript -e 'rmarkdown::render("$<", output_dir = "$(dir $@)", output_format = "distill::distill_article")'

clean:
	rm $(PDF)
	rm $(HTML)

view: 
	@open -a Skim $(PDF)