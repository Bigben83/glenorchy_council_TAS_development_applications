require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'
require 'cgi'

# Set up a logger to log the scraped data
logger = Logger.new(STDOUT)

# URL of the Glenorchy City Council planning applications page
url = "https://www.gcc.tas.gov.au/services/planning-and-building/planning-and-development/planning-applications/"

# Step 1: Fetch the page content
begin
  logger.info("Fetching page content from: #{url}")
  page_html = open(url).read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

# Step 2: Parse the page content using Nokogiri
doc = Nokogiri::HTML(page_html)

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create table
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS glenorchy (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_scraped TEXT,
    date_received TEXT,
    on_notice_to TEXT,
    address TEXT,
    council_reference TEXT,
    applicant TEXT,
    owner TEXT,
    stage_description TEXT,
    stage_status TEXT,
    document_description TEXT,
    title_reference TEXT
  );
SQL

# Define variables for storing extracted data for each entry
address = ''  
description = ''
on_notice_to = ''
title_reference = ''
date_received = ''
council_reference = ''
applicant = ''
owner = ''
stage_description = ''
stage_status = ''
document_description = ''
date_scraped = Date.today.to_s


# Loop through each content block in the main listing
doc.css('.content-block').each do |content_block|
  # Extract the address
  address = content_block.at_css('.content-block__title a').text.strip

  # Extract the closing date and parse it to the desired format
  on_notice_to = content_block.at_css('.content-block__date').text.strip
  on_notice_to = Date.strptime(on_notice_to.gsub("Closes:", "").strip, "%d %B %Y").to_s

  # Extract the description (if present)
  description = content_block.at_css('.content-block__description p')
  description = description ? description.text.strip : "No description available"

  # Extract the PDF download link
  document_description = content_block.at_css('.content-block__button a')['href']
  latitude = content_block.at_css('.content-block__map-link')['data-lat']
  longitude = content_block.at_css('.content-block__map-link')['data-lng']

  # Step 6: Ensure the entry does not already exist before inserting
  existing_entry = db.execute("SELECT * FROM glenorchy WHERE council_reference = ?", council_reference )

  if existing_entry.empty? # Only insert if the entry doesn't already exist
  # Step 5: Insert the data into the database
  db.execute("INSERT INTO glenorchy (address, on_notice_to, description, document_description, date_scraped)
              VALUES (?, ?, ?, ?, ?)", [address, on_notice_to, description, document_description, date_scraped])

  logger.info("Data for #{council_reference} saved to database.")
    else
      logger.info("Duplicate entry for application #{council_reference} found. Skipping insertion.")
    end
  
  # If you need to handle additional details, such as geolocation, it can be extracted as follows:
  lat = content_block.at_css('.content-block__map-link')['data-lat']
  lng = content_block.at_css('.content-block__map-link')['data-lng']
  logger.info("Latitude: #{lat}, Longitude: #{lng}")
end
