require "open-uri"
require "rexml/document"
require "yaml"

namespace :youtube do
  desc "Sincronizza gli ultimi video pubblici dal feed RSS di PosturaCorretta al catalog.yml"
  task sync: :environment do
    channel_id = "UC7LdGdDNfe_LUUqii42T4qA"
    rss_url = "https://www.youtube.com/feeds/videos.xml?channel_id=#{channel_id}"
    catalog_path = Rails.root.join("config", "data", "posturacorretta", "contenuti", "catalog.yml")

    puts "Caricamento del catalogo attuale..."
    catalog = YAML.load_file(catalog_path, permitted_classes: [], aliases: false) || {}
    
    # Raccogli tutti gli slug (video ID) esistenti
    existing_slugs = catalog.values.flat_map { |category| category["articles"].map { |a| a["slug"] } }

    puts "Scaricamento del feed RSS da #{rss_url}..."
    xml_data = URI.open(rss_url).read
    doc = REXML::Document.new(xml_data)

    new_videos = []
    
    # Analizza i video nell'RSS
    REXML::XPath.each(doc, "//entry") do |entry|
      video_id = REXML::XPath.first(entry, "yt:videoId").text
      title = REXML::XPath.first(entry, "title").text
      
      unless existing_slugs.include?(video_id)
        new_videos << {
          "title" => title,
          "excerpt" => "Nuovo video appena caricato sul canale YouTube di PosturaCorretta.",
          "slug" => video_id,
          "subcategory" => "Video Recenti",
          "time" => "10 min",
          "format" => "video",
          "author" => "mark"
        }
      end
    end

    if new_videos.empty?
      puts "Nessun nuovo video trovato. Il catalogo è già aggiornato."
    else
      puts "Trovati #{new_videos.size} nuovi video. Aggiunta alla categoria 'fisiologia' (di default)..."
      
      # Inserisci nella prima categoria che ha senso, per esempio 'fisiologia' (o una nuova)
      target_category = "fisiologia"
      
      if catalog[target_category] && catalog[target_category]["articles"]
        # Metti i nuovi video all'inizio della lista
        catalog[target_category]["articles"] = new_videos + catalog[target_category]["articles"]
      else
        puts "Categoria '#{target_category}' non trovata, creo una nuova..."
        catalog["nuovi"] = {
          "label" => "Nuovi Video",
          "eyebrow" => "Appena pubblicati",
          "icon" => "📺",
          "color" => "blue",
          "description" => "Gli ultimi video caricati sul canale YouTube.",
          "subcategories" => ["Video Recenti"],
          "articles" => new_videos
        }
      end

      # Salva il file
      File.open(catalog_path, "w") do |file|
        file.write(catalog.to_yaml)
      end
      
      puts "Fatto! #{new_videos.size} video salvati in config/data/posturacorretta/contenuti/catalog.yml"
    end
  end
end
