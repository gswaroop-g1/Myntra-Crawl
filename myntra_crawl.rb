require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'pp'

def user_agent
	{"User-Agent" => "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.10) Gecko/20100915 Ubuntu/10.04 (lucid) Firefox/3.6.10"}
end

$error_data = []


def process_page(page_id)
	url = "http://www.myntra.com/men-formal-shirts/page/#{page_id}"
	csv_file = File.open("./men-formal-shirts.csv", "a")
	begin
		page = Nokogiri::HTML(open(url, user_agent))
	rescue Exception => e
		puts "Error: #{page_id} #{e}"
		sleep(1.0/10.0)
		retry
	end
	products = page.css('div#mk-search-results li')#.css('div').select{|link| link['class']=='mk-prod-info'}
	products.each do |li|
		data_arr = []
		begin
			begin
				product_url = li.css('span[class=quick-look]')[0]["data-href"]
				# puts product_url
				sleep(1.0/10.0)
				product_url = "http://www.myntra.com"+product_url
				puts product_url
				product_page = Nokogiri::HTML(open(product_url, user_agent))
			rescue Exception => e
				puts "Error in loading product_page: #{e}"
			end
			begin
				data_arr << li.css('div[class=mk-prod-info]').css('span[class=mk-prod-brand-name]')[0].text
			rescue Exception => e
				li.css('span').each do |spn|
					puts spn.text
				end
				puts "Error in brand name: #{e}"
			end
			begin
				seller_name = product_page.css('div#vendorDetails span')[1].text
				data_arr << seller_name
			rescue Exception => e
				puts "Error in finding seller: #{e}"
				puts product_page.css('div#vendorDetails span').each do |spn|
					puts spn.text if(spn.text != nil)
				end
			end
			begin
				data_arr << li.css('div[class=mk-prod-info]').css('span[class=\'mk-prod-price red\']')[0].text.split(" ")[1].gsub(",","").to_i
			rescue Exception => e
				puts li.css('span[class=\'mk-prod-price red\']')[0].text
				puts "Error in price: #{e}"
			end
		rescue Exception => e
			puts "error in scraping #{e}"
			$error_data << e
		end
		p data_arr
		begin
			csv_file << data_arr if(!data_arr.empty?)
			csv_file << "\n" if(!data_arr.empty?)
		rescue Exception => e
			puts "Error Writing to file #{e}"
			retry
		end
	end
	csv_file.close
end

def main
	puts "Starting......."
	total_products = 628
	no_of_pages = (total_products/24).ceil
	(1..no_of_pages).each do |page_id|
		puts "page no. #{page_id}"
		process_page(page_id)
		sleep(1.0/5.0)
	end
end

main
p $error_data