#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "yaml"

SOURCE_DIR = "config/data/book_official"
BUILD_DIR  = "config/data/book_build"
OUTPUT_MD  = File.join(BUILD_DIR, "il-corpo-un-mondo-da-scoprire.md")

FileUtils.mkdir_p(BUILD_DIR)

files = Dir
  .glob(File.join(SOURCE_DIR, "*.md"))
  .sort

abort "❌ Nessun file .md trovato in #{SOURCE_DIR}" if files.empty?

def split_front_matter(content)
  if content.start_with?("---")
    parts = content.split(/^---\s*$/, 3)
    yaml = YAML.safe_load(parts[1]) || {}
    body = parts[2]&.lstrip || ""
    [yaml, body]
  else
    [{}, content]
  end
end

File.open(OUTPUT_MD, "w") do |out|
  files.each_with_index do |file, index|
    raw = File.read(file)
    meta, body = split_front_matter(raw)

    title       = meta["title"]
    description = meta["description"]

    out.puts "\n\n---\n\n" unless index.zero?

    if title
      out.puts "# #{title}\n\n"
    end

    if description
      out.puts "_#{description}_\n\n"
    end

    out.puts body.rstrip
  end
end

puts "✅ Libro generato correttamente"
puts "📘 Output: #{OUTPUT_MD}"
puts "📚 Capitoli: #{files.size}"
