class Creator
  require 'rss'
  require 'open-uri'
  require 'nokogiri'

  def initialize(title, url)
    @url = url
    @title = title
  end

  attr_reader :url, :title

  def create
    data = parse
    data.shift
    build(data)
  end

  private

  def parse
    Nokogiri::HTML(open(url)).css('table','tr').map do |row|
      begin
        date = row.css('font')[0].text.split(',').first.gsub!('Uploaded ','')
        date = date.gsub(160.chr("UTF-8"),"-")
        if date.include?(':')
          exp = date.split('-')
          exp[2] = Date.today.year
          date = exp.join('-')
        end
        {
          title: row.css('a')[2].attributes["title"].value,
          link:  row.css('a')[3].attributes["href"].value,
          date:  Date.strptime(date, '%m-%d-%Y')
        }
      rescue
        nil
      end
    end.compact
  end

  def build(data)
    rss = RSS::Maker.make("atom") do |maker|
      maker.channel.author = "a robot"
      maker.channel.about = "http://r.sett.me.uk/#{title}.rss"
      maker.channel.updated = Time.now.to_s
      maker.channel.title = title

      data.each do |scraped|
        maker.items.new_item do |item|
          item.link = scraped[:link]
          item.title = scraped[:title]
          item.updated = scraped[:date].to_s
        end
      end
    end
    rss
  end
end
