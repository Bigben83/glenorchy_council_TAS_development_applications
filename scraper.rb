require 'nokogiri'
require 'open-uri'
require 'date'
require 'logger'

# Set up a logger to log the scraped data
logger = Logger.new(STDOUT)

# URL of the Glenorchy City Council planning applications page
main_page_url = "https://www.gcc.tas.gov.au/services/planning-and-building/planning-and-development/planning-applications/"

# Open and parse the main page
main_page = Nokogiri::HTML(open(main_page_url))

# Loop through each content block in the main listing
main_page.css('.content-block').each do |content_block|
  # Extract the address
  address = content_block.at_css('.content-block__title a').text.strip

  # Extract the closing date and parse it to the desired format
  closing_date = content_block.at_css('.content-block__date').text.strip
  closing_date = Date.strptime(closing_date.gsub("Closes:", "").strip, "%d %B %Y").to_s

  # Extract the description (if present)
  description = content_block.at_css('.content-block__description p')
  description = description ? description.text.strip : "No description available"

  # Extract the PDF download link
  pdf_link = content_block.at_css('.content-block__button a')['href']

  # Log the extracted data
  logger.info("Address: #{address}, Closing Date: #{closing_date}, Description: #{description}, PDF Link: #{pdf_link}")
  
  # If you need to handle additional details, such as geolocation, it can be extracted as follows:
  lat = content_block.at_css('.content-block__map-link')['data-lat']
  lng = content_block.at_css('.content-block__map-link')['data-lng']
  logger.info("Latitude: #{lat}, Longitude: #{lng}")
end
