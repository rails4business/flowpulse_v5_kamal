# frozen_string_literal: true

require 'yaml'
require 'fileutils'

BOOK_DIR = File.expand_path('../config/data/books/il-corpo-un-mondo-da-scoprire', __dir__)
CHAPTERS_DIR = File.join(BOOK_DIR, 'chapters')
INDEX_YML_PATH = File.join(BOOK_DIR, 'index.yml')

# Ensure directories exist
FileUtils.mkdir_p(CHAPTERS_DIR)

# Sluggify helper
def sluggify(text)
  text.downcase
      .gsub(/[^a-z0-9\s\-]/, '')
      .strip
      .gsub(/\s+/, '-')
end

# Define parts, chapters, and colors
data = [
  {
    part: "Parte II — Quando si perde la salute",
    color: "rosso",
    chapters: {
      8 => "Dopo i quaranta... quando l'età sale è obbligatorio ammalarsi?",
      9 => "Il progresso ci ha fregato? Perchè oggi paghiamo ciò che una volta era gratis? Ogni epoca ha i suoi problemi",
      10 => "Bisogna stare bene per forza?",
      11 => "Chi decide per la nostra salute?",
      12 => "Tra medicina ufficiale e professioni del benessere",
      13 => "Tra mille professioni, a chi possiamo affidarci?",
      14 => "La fiducia: perché è così difficile costruire un percorso integrato?"
    }
  },
  {
    part: "Parte III — E' possibile creare un percorso integrato",
    color: "neutro",
    chapters: {
      15 => "Ogni epoca ha rimedi diversi",
      16 => "I sistemi chiusi e i loro limiti: Gödel e la medicina",
      17 => "Dalla fede nella religione alla fede nella ragione",
      18 => "Che cosa direbbe Dioniso?",
      19 => "La salute tra arte e scienza",
      20 => "Oggettivo e soggettivo: tra mappa e territorio",
      21 => "Conoscere significa poter scegliere",
      22 => "Sicurezza e libertà: dalla delega alla responsabilità"
    }
  },
  {
    part: "Parte IV — La postura come punto d'ingresso",
    color: "blu",
    chapters: {
      23 => "Non siamo tutti uguali",
      24 => "Per ognuno esiste un punto d'ingresso",
      25 => "Perché partire dalla postura e dalle metodiche posturali?",
      26 => "Conoscere come funziona il corpo",
      27 => "Dove può aiutarci la postura: patologie, prevenzione e performance",
      28 => "Lavorare su se stessi, nel gruppo e con l'altro",
      29 => "Un punto di partenza per costruire un percorso integrato"
    }
  },
  {
    part: "Parte V — Le capacità cognitive la base della nostra realtà",
    color: "viola",
    chapters: {
      30 => "Alla scoperta delle capacità cognitive",
      31 => "Le vulnerabilità interne: malattie degenerative e neurologiche",
      32 => "Le pressioni esterne: nuove tecnologie e cambiamento delle abitudini",
      33 => "La Quarta Via e la guerra dell'attenzione",
      34 => "Che cos'è la coscienza?",
      35 => "Che cosa abbiamo dimenticato?",
      36 => "La scoperta del mondo interiore",
      37 => "Il potere delle storie, delle parole e del significato",
      38 => "Antiche mappe: abbiamo più corpi?",
      39 => "La formazione e l'apprendimento: imparare dall'esperienza"
    }
  },
  {
    part: "Parte VI — ambiente gruppo attività esterno per rimanere in connessione",
    color: "verde",
    chapters: {
      40 => "Servono nuovi punti di vista da cui osservare il mondo",
      41 => "Corpo e ambiente: microcosmo e macrocosmo",
      42 => "Ambiente interno e ambiente esterno",
      43 => "Quali attività ti rendono veramente vivo?",
      44 => "Scoprire e coltivare il proprio potenziale",
      45 => "Tra individualità e gruppo",
      46 => "Possiamo cambiare abitudini e ambiente da soli?",
      47 => "Qual è il tuo ruolo nel gruppo?",
      48 => "Nuove forme per lotte antiche",
      49 => "Che cosa trasmettiamo ai nostri figli? Postura, DNA, abitudini e ambiente"
    }
  },
  {
    part: "Parte VII — Il nostro corpo, un giardino da coltivare da dove iniziare?",
    color: "viola", # matches giardino/violet
    chapters: {
      50 => "La proposta dell'Accademia PosturaCorretta",
      51 => "Postura e Fisiologia: imparare come funziona il corpo",
      52 => "Benessere Integrato: costruire percorsi per persone e professionisti",
      53 => "Informati, pratica, insegna",
      54 => "Eventi che uniscono salute, evoluzione ed espressione umana",
      55 => "Che cosa stai coltivando? Musica, danza, lotta, gioco, teatro e coltivazione",
      56 => "Il Giardino del Corpo: dagli eventi all'agriturismo rigenerativo",
      57 => "Dalle idee alle opere: organizzare impegni, progetti e collaborazioni"
    }
  }
]

# Read existing index.yml up to Parte I
existing_entries = YAML.load_file(INDEX_YML_PATH)
# Parte I matches entries 1-7
new_entries = existing_entries[0...7]

# Let's clean up existing files from chapters/ directory starting from 008 onwards
Dir.glob(File.join(CHAPTERS_DIR, '*.md')).each do |file_path|
  name = File.basename(file_path)
  num = name.split('-').first.to_i
  if num >= 8
    puts "Deleting old chapter file: #{name}"
    File.delete(file_path)
  end
end

# Counter for items in index.yml
item_counter = 8

data.each do |part_data|
  part_title = part_data[:part]
  part_color = part_data[:color]
  
  # Format section number
  section_num_str = format('%03d', item_counter)
  section_slug = sluggify(part_title)
  
  # 1. Create section markdown file
  section_filename = "#{section_num_str}-section-#{section_slug}.md"
  section_file_path = File.join(CHAPTERS_DIR, section_filename)
  
  section_content = <<~MARKDOWN
    ---
    title: #{part_title.inspect}
    description: #{part_title.inspect}
    color: "neutro"
    access: "hidden"
    status: "hidden"
    ---

    # #{part_title}

    Contenuto della sezione in fase di redazione.
  MARKDOWN
  
  File.write(section_file_path, section_content)
  puts "Created section file: #{section_filename}"
  
  # Add section to index.yml list
  new_entries << {
    "header" => false,
    "number" => section_num_str,
    "type" => "section",
    "title" => part_title,
    "description" => part_title,
    "slug" => section_slug,
    "color" => "neutro",
    "access" => "hidden"
  }
  
  item_counter += 1
  
  # 2. Create chapters markdown files
  part_data[:chapters].each do |ch_num, ch_title|
    ch_num_str = format('%03d', item_counter)
    ch_slug = sluggify(ch_title)
    ch_filename = "#{ch_num_str}-chapter-#{ch_slug}.md"
    ch_file_path = File.join(CHAPTERS_DIR, ch_filename)
    
    ch_content = <<~MARKDOWN
      ---
      title: #{ch_title.inspect}
      description: "Bozza del capitolo: #{ch_title}"
      color: #{part_color.inspect}
      access: "hidden"
      status: "hidden"
      ---

      # #{ch_title}

      Contenuto del capitolo in fase di redazione.
    MARKDOWN
    
    File.write(ch_file_path, ch_content)
    puts "Created chapter file: #{ch_filename}"
    
    new_entries << {
      "header" => false,
      "number" => ch_num_str,
      "type" => "chapter",
      "title" => ch_title,
      "description" => "Bozza del capitolo: #{ch_title}",
      "slug" => ch_slug,
      "color" => part_color,
      "access" => "hidden"
    }
    
    item_counter += 1
  end
end

# Write new index.yml
File.write(INDEX_YML_PATH, new_entries.to_yaml)
puts "Successfully updated index.yml with #{new_entries.size} entries!"
