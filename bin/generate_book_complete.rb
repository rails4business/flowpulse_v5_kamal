#!/usr/bin/env ruby
# generate_book_complete.rb
#
# Uso:
#   ruby generate_book_complete.rb ../config/data/book_index.yml ../config/data/book_complete
#
# Opzioni:
#   --force   sovrascrive i file delle 6 parti se esistono
#
# NOTE:
# - header: true  => SEZIONE
# - header: false => CAPITOLO (assegnato all'ultima sezione vista)
# - Split volumi: di default considera "Percorso salute" fino a PARTE V inclusa,
#   e "Professionisti" da PARTE VI in poi (regola basata sullo slug del header).
#
require "yaml"
require "fileutils"

STDOUT.sync = true

INDEX_PATH = ARGV[0].to_s.strip
OUT_DIR    = ARGV[1].to_s.strip
FORCE      = ARGV.include?("--force")

def die(msg, code: 1)
  puts "ERRORE: #{msg}"
  exit code
end

die("Uso: ruby #{File.basename(__FILE__)} path/book_index.yml path/output_dir [--force]") if INDEX_PATH.empty? || OUT_DIR.empty?
die("File non trovato: #{INDEX_PATH}") unless File.exist?(INDEX_PATH)

# ---------- helpers ----------
def safe_slug(s)
  s.to_s
   .downcase
   .strip
   .gsub(/[’']/,"")
   .gsub(/[^a-z0-9]+/, "-")
   .gsub(/\A-+|-+\z/, "")
end

def pad2(n) = n.to_i.to_s.rjust(2, "0")
def pad3(n) = n.to_i.to_s.rjust(3, "0")

PART_FILES = [
  ["01_pain.md",         "## 1. Il problema (Pain)\n\n"],
  ["02_ricerca.md",      "## 2. La ricerca della soluzione\n\n"],
  ["03_messa_in_atto.md","## 3. La messa in atto\n\n"],
  ["04_analisi.md",      "## 4. Analisi dei risultati\n\n"],
  ["05_linee_guida.md",  "## 5. Linee guida operative (base)\n\n"],
  ["06_call_to_action.md","## 6. Call to action\n\n"]
].freeze

def write_file(path, content, force: false)
  if File.exist?(path) && !force
    return :skipped
  end
  File.write(path, content)
  :written
end

def volume_for_section_slug(section_slug)
  # Regola default: da PARTE VI in poi => professionisti
  # Nel tuo indice gli slug sono tipo "parte-6-..." ecc.
  if section_slug.to_s =~ /\Aparte-(\d+)-/i
    n = Regexp.last_match(1).to_i
    return (n >= 6) ? "02_professionisti" : "01_percorso_salute"
  end
  # Intro/prologo ecc: percorso salute
  "01_percorso_salute"
end

def frontmatter_for(entry, kind:, section_title:)
  # Metto un front matter minimale utile in futuro
  <<~YML
  ---
  kind: #{kind}
  section: #{section_title.inspect}
  title: #{entry["title"].to_s.strip.inspect}
  slug: #{entry["slug"].to_s.strip.inspect}
  color: #{entry["color"].to_s.strip.inspect}
  ---
  YML
end

# ---------- load yaml ----------
begin
  raw = YAML.load_file(INDEX_PATH)
rescue Psych::SyntaxError => e
  die("Sintassi YAML non valida in #{INDEX_PATH}:\n#{e.message}")
end

die("Formato inatteso: mi aspettavo un Array di voci YAML") unless raw.is_a?(Array)

entries = raw.select { |x| x.is_a?(Hash) }

# ---------- build structure model ----------
sections = []
current_section = nil

entries.each_with_index do |e, idx|
  header = e["header"] == true
  title  = e["title"].to_s.strip
  slug   = e["slug"].to_s.strip
  color  = e["color"].to_s.strip
  desc   = (e["description"] || "").to_s.strip

  if title.empty? || slug.empty?
    die("Voce indice incompleta @#{idx + 1}: title/slug mancanti (#{e.inspect[0, 120]}...)")
  end

  if header
    current_section = {
      "title" => title,
      "slug" => slug,
      "color" => color,
      "description" => desc,
      "chapters" => []
    }
    sections << current_section
  else
    # capitolo senza sezione: lo mettiamo in una sezione "00_misc" dentro percorso salute
    if current_section.nil?
      current_section = {
        "title" => "00 – Senza sezione",
        "slug" => "00-senza-sezione",
        "color" => "neutro",
        "description" => "Capitoli prima della prima sezione header",
        "chapters" => []
      }
      sections << current_section
    end

    current_section["chapters"] << {
      "title" => title,
      "slug" => slug,
      "color" => color,
      "description" => desc
    }
  end
end

# ---------- create directories ----------
FileUtils.mkdir_p(OUT_DIR)

puts "== Generazione book_complete =="
puts "Index:  #{INDEX_PATH}"
puts "Out:    #{OUT_DIR}"
puts "Force:  #{FORCE ? "YES" : "NO"}"
puts

written = 0
skipped = 0

# numerazioni per sezioni per volume
section_counts = Hash.new(0)

sections.each do |sec|
  vol = volume_for_section_slug(sec["slug"])
  section_counts[vol] += 1
  sec_no = section_counts[vol]

  vol_dir = File.join(OUT_DIR, vol)
  FileUtils.mkdir_p(vol_dir)

  section_dir_name = "#{pad2(sec_no)}_sezione_#{safe_slug(sec["slug"].empty? ? sec["title"] : sec["slug"])}"
  section_dir = File.join(vol_dir, section_dir_name)
  FileUtils.mkdir_p(section_dir)

  # README sezione
  readme_path = File.join(section_dir, "README.md")
  readme = +"# #{sec["title"]}\n\n"
  readme << "#{sec["description"]}\n\n" unless sec["description"].empty?
  readme << "## Capitoli\n\n"
  if sec["chapters"].empty?
    readme << "_(Nessun capitolo in questa sezione)_\n"
  else
    sec["chapters"].each_with_index do |ch, i|
      readme << "- #{pad2(i + 1)}. #{ch["title"]} (`#{ch["slug"]}`)\n"
    end
  end
  case write_file(readme_path, readme, force: false)
  when :written then written += 1
  when :skipped then skipped += 1
  end

  # capitoli
  sec["chapters"].each_with_index do |ch, i|
    chapter_dir_name = "#{pad2(i + 1)}_capitolo_#{safe_slug(ch["slug"].empty? ? ch["title"] : ch["slug"])}"
    chapter_dir = File.join(section_dir, chapter_dir_name)
    FileUtils.mkdir_p(chapter_dir)

    PART_FILES.each do |fname, heading|
      fpath = File.join(chapter_dir, fname)
      fm = frontmatter_for(ch, kind: "chapter_part", section_title: sec["title"])
      content = fm + "\n# #{ch["title"]}\n\n" + heading
      case write_file(fpath, content, force: FORCE)
      when :written then written += 1
      when :skipped then skipped += 1
      end
    end
  end
end

puts "✅ Fatto."
puts "File scritti:   #{written}"
puts "File saltati:   #{skipped}"
puts
puts "Suggerimento: per vedere la struttura:"
puts "  tree -L 4 #{OUT_DIR} | sed -n '1,120p'  # (se hai tree)"
puts "  find #{OUT_DIR} -maxdepth 4 -type d | sed -n '1,120p'"
