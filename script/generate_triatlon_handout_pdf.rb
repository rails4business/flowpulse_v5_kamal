# frozen_string_literal: true

# Generates a lightweight, print-ready A4 two-page PDF without external gems.
require "shellwords"

OUTPUT = Rails.root.join("docs/handouts/Presentazione PosturaCorretta.pdf")
PAGE_WIDTH = 595.28
PAGE_HEIGHT = 841.89

class PdfPage
  def initialize
    @commands = ["0.08 0.13 0.17 rg", "0.08 0.13 0.17 RG"]
  end

  def rectangle(x, y, width, height, fill: nil, stroke: nil, radius: false)
    if fill
      @commands << format("%.3f %.3f %.3f rg", *fill)
    end
    if stroke
      @commands << format("%.3f %.3f %.3f RG", *stroke)
    end
    @commands << format("%.2f %.2f %.2f %.2f re %s", x, y, width, height, fill && stroke ? "B" : fill ? "f" : "S")
  end

  def text(x, y, value, size: 10, bold: false, color: [0.08, 0.13, 0.17])
    escaped = value.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").gsub(/([\\()])/, '\\\\1')
    @commands << format("%.3f %.3f %.3f rg", *color)
    @commands << "BT /#{bold ? 'F2' : 'F1'} #{size} Tf 1 0 0 1 #{x.round(2)} #{y.round(2)} Tm (#{escaped}) Tj ET"
  end

  def lines(x, y, value, width:, size: 10, leading: nil, bold: false, color: [0.08, 0.13, 0.17])
    leading ||= size * 1.38
    words = value.split(/\s+/)
    rows, row = [], ""
    words.each do |word|
      candidate = row.empty? ? word : "#{row} #{word}"
      if candidate.length * size * 0.49 > width && !row.empty?
        rows << row
        row = word
      else
        row = candidate
      end
    end
    rows << row unless row.empty?
    rows.each_with_index { |line, index| text(x, y - (index * leading), line, size: size, bold: bold, color: color) }
    y - (rows.length * leading)
  end

  def image(name, x, y, width, height)
    @commands << "q #{width} 0 0 #{height} #{x} #{y} cm /#{name} Do Q"
  end

  def content
    @commands.join("\n")
  end
end

def front
  page = PdfPage.new
  # Screenshot supplied for the handout: keep its original proportions and
  # centre it on a white A4 page rather than stretching it to the paper.
  page.rectangle(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill: [1, 1, 1])
  page.image("Im4", 42, 745, 170, 28)
  page.image("Im1", 37, 167, 520, 507)
  return page

  teal = [0.05, 0.45, 0.43]
  muted = [0.31, 0.38, 0.43]
  page.text(42, 795, "POSTURACORRETTA  |  PROPOSTA PER CHI PRATICA TRIATHLON", size: 8, bold: true, color: teal)
  page.text(42, 751, "Allenare la prestazione.", size: 25, bold: true)
  page.text(42, 721, "Conoscere e rispettare il corpo.", size: 25, bold: true)
  page.lines(42, 685, "Nuoto, bici e corsa chiedono continuita, adattamento e recupero. I tre progetti lavorano insieme per rendere l'allenamento piu consapevole, sostenibile e collegato alla vita reale.", width: 500, size: 12, color: muted)
  page.rectangle(42, 634, 510, 2, fill: teal)
  cards = [
    ["01  POSTURACORRETTA", "Capire e praticare", "Un percorso di educazione al corpo: postura, movimento, presenza e strumenti pratici.", ["osservare abitudini e compensi", "migliorare mobilita, respiro e recupero", "portare nella settimana pratiche sostenibili"]],
    ["02  PERCORSO INTEGRATO", "Mettere in relazione", "Quando serve, collega persona, professionisti, luoghi e obiettivi senza confondere ruoli e informazioni.", ["un quadro leggibile del percorso", "incontri e verifiche coordinati", "attenzione alla persona, non solo alla prestazione"]],
    ["03  IL GIARDINO DEL CORPO", "Fare esperienza", "Uno spazio per incontrare corpo, natura, apprendimento ed espressione attraverso esperienze condivise.", ["attivita nel territorio e nella natura", "pratica, relazione e comunita", "eventi che danno forma al percorso"]]
  ]
  cards.each_with_index do |(label, title, description, bullets), index|
    x = 42 + index * 174
    page.rectangle(x, 378, 162, 232, fill: [0.985, 0.99, 0.99], stroke: [0.84, 0.88, 0.89])
    page.text(x + 12, 589, label, size: 8, bold: true, color: teal)
    page.text(x + 12, 560, title, size: 14, bold: true)
    y = page.lines(x + 12, 537, description, width: 138, size: 9, color: muted) - 8
    bullets.each { |bullet| y = page.lines(x + 14, y, "- #{bullet}", width: 136, size: 8.5, color: muted) - 5 }
    page.image("Im#{index + 1}", x + 12, 388, 138, 42)
  end
  page.rectangle(42, 250, 510, 100, fill: [0.92, 0.97, 0.96])
  page.text(58, 324, "Perche farli insieme", size: 15, bold: true, color: [0.08, 0.30, 0.28])
  page.lines(58, 299, "PosturaCorretta da strumenti concreti. Percorso Integrato aiuta a scegliere e coordinare quando il bisogno e piu complesso. Il Giardino del Corpo offre luoghi ed esperienze per praticare, incontrarsi e dare continuita al percorso. Non sono tre servizi sovrapposti: sono tre livelli dello stesso progetto.", width: 475, size: 10, color: [0.16, 0.34, 0.32])
  page.lines(42, 190, "Primo passo: un incontro per capire da dove partire, senza promettere soluzioni standard e senza sostituire valutazioni mediche o professionali necessarie.", width: 510, size: 9, color: muted)
  page
end

def back
  page = PdfPage.new
  teal = [0.05, 0.45, 0.43]
  muted = [0.31, 0.38, 0.43]
  page.text(42, 795, "POSTURACORRETTA  |  PERCORSO DI STUDIO E PRATICA", size: 8, bold: true, color: teal)
  page.image("Im4", 405, 782, 140, 23)
  page.text(42, 757, "Sezioni e corsi online", size: 24, bold: true)
  page.text(405, 757, "Studio autonomo + lezioni pratiche", size: 8.5, color: muted)
  sections = [
    ["Inizia da qui", "Un primo orientamento per osservare il corpo e impostare una pratica personale.", [["PosturaCorretta in un mese", "Basi del metodo, osservazione, benefici e prima pratica."], ["Postura e Fisiologia", "Ambiti, aree e relazioni tra sistemi del corpo."]]],
    ["Postura e Recupero", "Approfondimenti per comprendere meglio movimento, sistemi corporei e metodiche.", [["Intro: basi e fondamenti", "Orientamento e linguaggio comune."], ["Igiene Posturale", "Mobilita, tensioni, recettori e abitudini."], ["Principi di Fisioterapia", "Respirazione, sistemi e recupero."], ["Biomeccanica comportamentale (GDS)", "Direzioni di movimento e catene."], ["Principi di Osteopatia", "Fasce, visceri, cranio-sacrale e regolazione."], ["Corpo e Coscienza", "Circolazioni, centri di gravita e consapevolezza."], ["Altre metodiche posturali", "Kinesiologia applicata, Feldenkrais e Alexander."]]]
  ]
  y = 720
  sections.each do |title, description, courses|
    height = title == "Inizia da qui" ? 135 : 290
    page.rectangle(42, y - height, 510, height, fill: [0.965, 0.98, 0.98])
    page.rectangle(42, y - height, 4, height, fill: teal)
    page.text(58, y - 25, title, size: 14, bold: true, color: [0.07, 0.24, 0.25])
    page.lines(58, y - 43, description, width: 470, size: 9, color: muted)
    courses.each_with_index do |(course, note), index|
      col, row = index % 2, index / 2
      x = 58 + col * 237
      cy = y - 73 - row * 49
      page.rectangle(x, cy - 34, 222, 40, fill: [1, 1, 1], stroke: [0.84, 0.88, 0.89])
      page.text(x + 8, cy - 10, course, size: 8.6, bold: true)
      page.lines(x + 8, cy - 22, note, width: 202, size: 7.4, color: muted)
    end
    y -= height + 14
  end
  page.text(42, 252, "Come si usa", size: 14, bold: true, color: [0.07, 0.24, 0.25])
  [["1  Corsi online", "Leggi capitoli e consulta le schede pratiche con i tuoi tempi."], ["2  Programma lezioni", "Quando vuoi praticare, scegli una lezione con massaggio, movimento e meditazione."], ["3  Incontro reale", "Le date si prenotano solo quando sono pubblicate da insegnante o professionista."]].each_with_index do |(title, text), index|
    x = 42 + index * 174
    page.rectangle(x, 155, 162, 76, fill: [0.97, 0.97, 0.99])
    page.text(x + 10, 211, title, size: 9, bold: true, color: [0.31, 0.23, 0.47])
    page.lines(x + 10, 193, text, width: 140, size: 8, color: muted)
  end
  page.text(42, 84, "PosturaCorretta - conoscere il corpo, allenare l'ascolto e costruire continuita nel tempo.", size: 8.5, color: muted)
  page
end

pages = [front, back]
objects = []
objects << "<< /Type /Catalog /Pages 2 0 R >>"
objects << "<< /Type /Pages /Kids [3 0 R 5 0 R] /Count 2 >>"
pages.each_with_index do |page, index|
  content_id = 4 + (index * 2)
  images = " /XObject << /Im1 9 0 R /Im2 10 0 R /Im3 11 0 R /Im4 12 0 R >>"
  objects << "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{PAGE_WIDTH} #{PAGE_HEIGHT}] /Resources << /Font << /F1 7 0 R /F2 8 0 R >>#{images} >> /Contents #{content_id} 0 R >>"
  stream = page.content
  objects << "<< /Length #{stream.bytesize} >>\nstream\n#{stream}\nendstream"
end
objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"

def jpeg_dimensions(data)
  offset = 2
  while offset < data.bytesize
    offset += 1 while data.getbyte(offset) != 0xFF && offset < data.bytesize
    marker = data.getbyte(offset + 1)
    offset += 2
    next if [0xD8, 0xD9].include?(marker)
    length = data.byteslice(offset, 2).unpack1("n")
    if (0xC0..0xC3).cover?(marker)
      return data.byteslice(offset + 3, 4).unpack("nn").reverse
    end
    offset += length
  end
end

%w[tre_progetti_fronte percorso_integrato giardino_del_corpo posturacorretta_logo].each do |name|
  data = File.binread(Rails.root.join("tmp/triatlon_pdf_assets/#{name}.jpg"))
  width, height = jpeg_dimensions(data)
  objects << "<< /Type /XObject /Subtype /Image /Width #{width} /Height #{height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length #{data.bytesize} >>\nstream\n#{data}\nendstream"
end

pdf = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n".b
offsets = [0]
objects.each_with_index do |object, index|
  offsets << pdf.bytesize
  pdf << "#{index + 1} 0 obj\n#{object}\nendobj\n"
end
xref = pdf.bytesize
pdf << "xref\n0 #{objects.size + 1}\n0000000000 65535 f \n"
offsets.drop(1).each { |offset| pdf << format("%010d 00000 n \n", offset) }
pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref}\n%%EOF\n"
File.binwrite(OUTPUT, pdf)
puts OUTPUT
