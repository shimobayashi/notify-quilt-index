require 'json'
require 'httparty'

require_relative 'quilt_index_calculator'

def lambda_handler(event:, context:)
  info = QuiltIndexCalculator.quilt_index_and_info({
    temperature: fetch_current_metric('natureremo.temperature.Remo'),
    humidity: fetch_current_metric('natureremo.humidity.Remo'),
  })
  message = "お布団指数の実測値は #{info[:quilt_index].round(1)} でした。これは #{info[:suggestion][:short]} の水準で、寝具は #{info[:suggestion][:long]} をおすすめします。"

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

def fetch_current_metric(name)
  now = Time.now.to_i
  response = HTTParty.get(
    'https://api.mackerelio.com/api/v0/services/home/metrics',
    :headers => {
      'X-Api-Key' => ENV['MACKEREL_API_KEY'],
    },
    :query => {
      name: name,
      # Mackerel内部では300秒ごとに値を保存しているようで、最新の値以外は要らないのでfromには300秒前を指定。
      from: now - 300,
      to:   now,
    },
  )
  json = JSON.parse(response.body)
  return json['metrics'].last['value']
end