require 'uri'
require 'net/http'
require 'nokogiri'
require 'time'

class ScraperController < ApplicationController
  def scrape
    @links = []
    # do the scraping
    base_uri = 'https://www.theverge.com/archives/'
    year_start = Time.new.year
    year_end = 2022
    # year current - 2022
    year_start.step(year_end, -1) do |year|
      # month 12 - 1
      12.step(1, -1) do |month|
        # Skip if month > current year's month, nothing to scrape
        next if year == Time.new.year && month > Time.new.month

        month_uri = "#{base_uri}#{year}/#{month}/"
        # check month page
        real_uri = URI(month_uri)
        response = Net::HTTP.get_response(real_uri)
        doc = Nokogiri::HTML(response.body)
        span = doc.css('li.is-selected > a > span.c-filter-list__count')
        # Check number of articles
        articles_for_month = span.first.inner_text.to_i
        # 30 articles per page
        articles_per_page = 30.0
        # Get number of pages to be scraped
        page_month = (articles_for_month / articles_per_page).ceil
        # query page one until .. page_month
        1.step(page_month, 1) do |page|
          page_uri = "#{month_uri}/#{page}"
          page_request = URI(page_uri)
          page_response = Net::HTTP.get_response(page_request)
          page_doc = Nokogiri::HTML(page_response.body)
          # All entries on that page
          entries = page_doc.css('div.c-entry-box--compact__body')
          entries.each do |entry|
            # Get title
            title = entry.css('h2').first.text
            # Get url link
            url = ""
            url = entry.css('a').first.attribute.('href').value
            @links << [{title:, url:}]
          end
        end
      end
    end
  end
end
