all: appeal.pdf appeal.docx


appeal.docx : appeal.md
	pandoc $< -o $@

appeal.pdf : appeal.md
	pandoc $< -o $@ --pdf-engine xelatex