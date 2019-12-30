require 'json'
require 'mechanize'
require 'httparty'

require_relative 'quilt_index_calculator'

def lambda_handler(event:, context:)
  agent = Mechanize.new
  page = agent.get('http://www.tenki.jp/forecast/6/29/6110/26104.html')
  
  heads = page.search('tr.head td')
  hours = page.search('tr.hour td')
  temps = page.search('tr.temperature td')
  humds = page.search('tr.humidity td')
  metrics = []
  2.times do |i_head| # 今日 明日
    8.times do |i_hour| # 0時から24時まで3時間ごと
      i_col = i_hour + i_head * 8
      head = heads[i_head].content
      hour = hours[i_hour].content.to_i
      temp = temps[i_col].content.to_f
      humd = humds[i_col].content.to_f
      metrics << {
        temperature: temp,
        humidity:    humd,
      }
    end
  end
  
  # 0時～9時における平均を算出する
  r = 8..10
  temps = metrics[r].map{ |item| item[:temperature] }
  avg_temp = temps.sum / temps.length
  humds = metrics[r].map{ |item| item[:humidity] }
  avg_humd = humds.sum / humds.length

  info = QuiltIndexCalculator.quilt_index_and_info({
    temperature: avg_temp,
    humidity: avg_humd,
  })
  message = "本日のお布団指数は #{info[:quilt_index].round(1)} です。これは #{info[:suggestion][:short]} の水準で、寝具は #{info[:suggestion][:long]} をおすすめします。"

  puts ENV['LINE_NOTIFY_API_KEY']
  response = HTTParty.post(
    'https://notify-api.line.me/api/notify',
    :headers => {
      'Authorization' => "Bearer #{ENV['LINE_NOTIFY_API_KEY']}",
    },
    :body => {
      'message' => message,
    },
  )

  {
    statusCode: response.code,
    body: {
      message: response.to_s,
    }.to_json
  }
end
