require 'nokogiri'

html = File.read('tmp_test.html')
doc = Nokogiri::HTML(html)

['path-modal', 'close-modal-btn', 'modal-cancel-btn', 'modal-select-btn', 'selected-paths-text', 'start-whatsapp-link'].each do |id|
  el = doc.css("##{id}")
  puts "ID: #{id} -> Count: #{el.length}"
end

cards = doc.css("#percorso .pc-choice")
puts "Cards inside #percorso Count: #{cards.length}"
