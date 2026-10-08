# frozen_string_literal: true

# Generates the shareable presentation linked from the organiser tab.
# Run with: ruby script/generate_posturacorretta_eventi_pdf.rb

require "fileutils"

OUTPUT = File.expand_path("../docs/handouts/PosturaCorretta per eventi sportivi.pdf", __dir__)
PAGE_WIDTH = 595
PAGE_HEIGHT = 842
MARGIN = 54

def pdf_text(value)
  value.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
       .gsub(/([\\()])/, '\\\\\1')
end

def wrap(text, width)
  text.split(/\s+/).each_with_object([""]) do |word, lines|
    if lines.last.empty? || "#{lines.last} #{word}".length <= width
      lines[-1] = [lines.last, word].reject(&:empty?).join(" ")
    else
      lines << word
    end
  end
end

class PdfPage
  attr_reader :commands

  def initialize
    @commands = []
    @y = PAGE_HEIGHT - MARGIN
  end

  def space(points)
    @y -= points
  end

  def rule(color = "0.82 0.88 0.96")
    @commands << "#{color} RG #{MARGIN} #{@y} m #{PAGE_WIDTH - MARGIN} #{@y} l S"
    @y -= 18
  end

  def label(text)
    write(text.upcase, size: 9, font: :bold, color: "0.11 0.31 0.68", leading: 13, width: 86)
  end

  def heading(text, size: 23)
    write(text, size:, font: :bold, color: "0.06 0.09 0.16", leading: size + 5, width: size > 20 ? 42 : 55)
  end

  def paragraph(text, bold: false)
    write(text, size: 11, font: bold ? :bold : :regular, color: "0.24 0.29 0.38", leading: 16, width: 76)
  end

  def bullet(text)
    lines = wrap(text, 70)
    @commands << text_command("•", MARGIN + 2, @y, 11, :bold, "0.11 0.31 0.68")
    lines.each_with_index do |line, index|
      @commands << text_command(line, MARGIN + 18, @y - (index * 15), 10.5, :regular, "0.20 0.25 0.34")
    end
    @y -= (lines.length * 15) + 5
  end

  def numbered(number, title, description)
    @commands << "0.11 0.31 0.68 rg #{MARGIN} #{@y - 3} 24 24 re f"
    @commands << text_command(number.to_s, MARGIN + 8, @y + 4, 10, :bold, "1 1 1")
    @commands << text_command(title, MARGIN + 36, @y + 5, 12, :bold, "0.06 0.09 0.16")
    @y -= 18
    wrap(description, 70).each do |line|
      @commands << text_command(line, MARGIN + 36, @y, 10.5, :regular, "0.24 0.29 0.38")
      @y -= 15
    end
    @y -= 9
  end

  def callout(title, text)
    height = 88
    @commands << "0.93 0.96 1 rg #{MARGIN} #{@y - height + 12} #{PAGE_WIDTH - (MARGIN * 2)} #{height} re f"
    @commands << text_command(title, MARGIN + 18, @y - 10, 14, :bold, "0.08 0.24 0.52")
    wrap(text, 68).each_with_index do |line, index|
      @commands << text_command(line, MARGIN + 18, @y - 32 - (index * 15), 10.5, :regular, "0.16 0.25 0.39")
    end
    @y -= height + 8
  end

  private

  def write(text, size:, font:, color:, leading:, width:)
    wrap(text, width).each do |line|
      @commands << text_command(line, MARGIN, @y, size, font, color)
      @y -= leading
    end
    @y -= 5
  end

  def text_command(text, x, y, size, font, color)
    font_key = font == :bold ? "F2" : "F1"
    "BT /#{font_key} #{size} Tf #{color} rg #{x} #{y} Td (#{pdf_text(text)}) Tj ET"
  end
end

pages = []

page = PdfPage.new
page.label("PosturaCorretta · Presentazione per organizzatori")
page.space(5)
page.heading("Porta l’educazione alla salute nel tuo evento sportivo")
page.space(6)
page.paragraph("Uno spazio dedicato alla postura, al recupero e alla conoscenza del corpo, gestito sul posto dagli operatori PosturaCorretta.", bold: true)
page.space(12)
page.rule
page.label("Cosa portiamo all’evento")
page.heading("Uno spazio PosturaCorretta nel tuo evento", size: 19)
page.paragraph("Nel giorno e negli orari concordati, uno o più operatori arrivano con l’allestimento e il materiale necessario. Accolgono le persone, presentano il percorso PosturaCorretta, guidano la scheda iniziale e, quando previsto, propongono un breve trattamento.")
page.callout("Chi porta cosa", "L’organizzatore mette a disposizione lo spazio. PosturaCorretta porta gli operatori, il gazebo, uno o più lettini e il materiale per le attività.")
page.label("Che cosa viene proposto")
page.bullet("Accoglienza delle persone nello spazio PosturaCorretta.")
page.bullet("Presentazione del progetto e scheda iniziale con semplici esercizi per migliorare la postura.")
page.bullet("Un breve trattamento dimostrativo coerente con la professione dell’operatore.")
page.bullet("Rotoli di carta per i lettini e disinfettante per le mani.")
page.bullet("Materiale informativo e strumenti necessari ai trattamenti dei singoli professionisti.")
pages << page

page = PdfPage.new
page.label("Organizzazione della giornata")
page.heading("Come ci organizziamo", size: 22)
page.numbered(1, "Prima dell’evento", "Concordiamo giorno, orari, accesso per lo scarico, preparazione e spazio disponibile per gazebo e lettino.")
page.numbered(2, "Durante l’evento", "Gli operatori accolgono le persone, presentano PosturaCorretta e guidano semplici esercizi e brevi trattamenti.")
page.numbered(3, "Chiusura", "All’orario concordato smontiamo l’allestimento e ripuliamo lo spazio.")
page.space(8)
page.rule
page.label("Vantaggi per l’organizzatore")
page.bullet("Un servizio gratuito in più per atleti, accompagnatori e pubblico.")
page.bullet("Uno spazio in cui parlare in modo concreto di corpo, postura e recupero.")
page.bullet("Un’attività gestita dagli operatori negli orari concordati.")
page.bullet("La possibilità di costruire in seguito un percorso per società, squadre o gruppi di lavoro.")
page.space(8)
page.label("Che cosa serve")
page.bullet("Uno spazio adeguato per il gazebo e lo svolgimento delle attività.")
page.bullet("Accesso per carico, montaggio e smontaggio.")
page.bullet("Orari di inizio e fine e inserimento nel programma della giornata.")
page.bullet("Accordi su come comunicare lo spazio PosturaCorretta ai partecipanti.")
pages << page

page = PdfPage.new
page.label("Dopo la giornata")
page.heading("Se volete continuare dopo l’evento", size: 22)
page.paragraph("Possiamo fermarci alla giornata di presentazione oppure organizzare un percorso dedicato ad atleti, squadre, società o aziende.")
page.space(8)
page.heading("Un ciclo di 3 o 5 incontri", size: 18)
page.bullet("Educazione alla salute e semplici esercizi utilizzabili tra un incontro e l’altro.")
page.bullet("Momenti individuali nei quali ogni professionista interviene entro le proprie competenze.")
page.bullet("Numero di persone, operatori, tempi e condizioni definiti insieme all’organizzazione.")
page.space(14)
page.callout("Raccontaci come sarà il tuo evento", "Scrivi a markpostura@gmail.com indicando tipo di manifestazione, luogo, data, orari, numero indicativo di partecipanti e spazio disponibile. Valuteremo insieme come partecipare.")
page.space(8)
page.paragraph("Le attività della giornata sono gratuite per chi partecipa. Lasciare i contatti o iscriversi è facoltativo. Ogni operatore interviene esclusivamente entro le competenze della propria professione.")
pages << page

objects = []
objects << "<< /Type /Catalog /Pages 2 0 R >>"
objects << nil
objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"

page_ids = []
pages.each do |pdf_page|
  page_id = objects.length + 1
  content_id = page_id + 1
  page_ids << page_id
  objects << "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{PAGE_WIDTH} #{PAGE_HEIGHT}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents #{content_id} 0 R >>"
  stream = pdf_page.commands.join("\n")
  objects << "<< /Length #{stream.bytesize} >>\nstream\n#{stream}\nendstream"
end
objects[1] = "<< /Type /Pages /Kids [#{page_ids.map { |id| "#{id} 0 R" }.join(' ')}] /Count #{page_ids.length} >>"

pdf = +"%PDF-1.4\n%\xE2\xE3\xCF\xD3\n".b
offsets = [0]
objects.each_with_index do |object, index|
  offsets << pdf.bytesize
  pdf << "#{index + 1} 0 obj\n#{object}\nendobj\n".b
end
xref_offset = pdf.bytesize
pdf << "xref\n0 #{objects.length + 1}\n0000000000 65535 f \n".b
offsets.drop(1).each { |offset| pdf << format("%010d 00000 n \n", offset).b }
pdf << "trailer\n<< /Size #{objects.length + 1} /Root 1 0 R >>\nstartxref\n#{xref_offset}\n%%EOF\n".b

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.binwrite(OUTPUT, pdf)
puts "Generated #{OUTPUT} (#{pages.length} pages)"
