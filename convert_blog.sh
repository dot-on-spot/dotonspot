#!/bin/bash

# Script to convert DOCX files to Markdown for Jekyll blog
# Requirements: pandoc must be installed

BLOG_DIR="_blog"
OUTPUT_DIR="_posts"

# Create _posts directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to create a Jekyll-friendly filename
create_jekyll_filename() {
    local title="$1"
    local date=$(date +%Y-%m-%d)

    # Convert title to lowercase, replace spaces with hyphens, remove special chars
    local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/ /-/g' | sed 's/--*/-/g')

    echo "${date}-${slug}.md"
}

# Function to create Jekyll front matter
create_front_matter() {
    local title="$1"
    local date=$(date +"%Y-%m-%d %H:%M:%S %z")

    cat << EOF
---
layout: post
title: "$title"
date: $date
categories: [blog, dot-physical, trucking]
author: DOT on Spot
excerpt: ""
image: ""
---

EOF
}

# Function to clean up markdown content
clean_markdown() {
    local file="$1"

    # Remove extra blank lines and clean up formatting
    sed -i '/^[[:space:]]*$/N;/^\n$/d' "$file"

    # Fix common markdown issues from Word conversion
    sed -i 's/\*\*\*\*/\*\*/g' "$file"  # Fix bold formatting
    sed -i 's/\_\_\_\_/\_\_/g' "$file"    # Fix italic formatting
}

echo "Starting DOCX to Markdown conversion..."
echo "========================================"

# Process each DOCX file
find "$BLOG_DIR" -name "*.docx" -type f | while IFS= read -r file; do
    # Get the base filename without extension
    base_name=$(basename "$file" .docx)

    # Skip files that might cause issues
    if [[ "$base_name" =~ ^Untitled || "$base_name" =~ ^\. ]]; then
        echo "Skipping: $base_name"
        continue
    fi

    echo "Processing: $base_name"

    # Create Jekyll filename
    jekyll_filename=$(create_jekyll_filename "$base_name")
    output_file="$OUTPUT_DIR/$jekyll_filename"

    # Create the front matter
    create_front_matter "$base_name" > "$output_file"

    # Convert DOCX to markdown and append
    if pandoc "$file" -f docx -t markdown --wrap=none --extract-media=images >> "$output_file" 2>/dev/null; then
        echo "✓ Converted: $jekyll_filename"

        # Clean up the markdown
        clean_markdown "$output_file"
    else
        echo "✗ Failed to convert: $base_name"
        rm -f "$output_file"
    fi
done

echo "========================================"
echo "Conversion completed!"
echo "Don't forget to:"
echo "1. Review and edit the converted markdown files"
echo "2. Add appropriate excerpts to the front matter"
echo "3. Add featured images if needed"
echo "4. Update categories and tags as needed"
