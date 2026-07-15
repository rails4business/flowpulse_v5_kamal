require 'selenium-webdriver'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-gpu')

driver = Selenium::WebDriver.for :chrome, options: options

begin
  driver.navigate.to 'http://localhost:3000/posturacorretta/percorso'
  puts "Page title: #{driver.title}"
  
  # Print any console logs on load
  puts "--- Console logs on load ---"
  driver.logs.get(:browser).each do |log|
    puts "[#{log.level}] #{log.message}"
  end

  # Find the card with data-choice="Cura e Riabilitazione"
  card = driver.find_element(css: '[data-choice="Cura e Riabilitazione"]')
  puts "Found card: #{card.text.gsub("\n", ' ')}"
  
  card.click
  puts "Clicked card!"
  sleep 1

  # Check if modal is visible
  modal = driver.find_element(css: '#path-modal')
  puts "Modal class list: #{modal.attribute('class')}"
  puts "Modal displayed?: #{modal.displayed?}"
  
  # Print any console logs after click
  puts "--- Console logs after click ---"
  driver.logs.get(:browser).each do |log|
    puts "[#{log.level}] #{log.message}"
  end

rescue => e
  puts "Error: #{e.message}"
ensure
  driver.quit
end
