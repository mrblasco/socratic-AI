#!/bin/bash

OUTDIR=docs
FORMAT="all"   # default

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --pdf) FORMAT="bookdown::pdf_document2";;
        --html) FORMAT="distill::distill_article";;
        --word) FORMAT="bookdown::word_document2";;
        --all) FORMAT="all";;
        *) echo "Unknown flag: $1"; exit 1;;
    esac
    shift
done

if [ ! -d "$OUTDIR" ]; then
    echo "Creating outdir $OUTDIR"
    mkdir -p "$OUTDIR"
fi

echo "Rendering report to $OUTDIR (format: $FORMAT)..."
Rscript -e "rmarkdown::render('main_report.Rmd', output_dir='$OUTDIR', output_format='$FORMAT')"
