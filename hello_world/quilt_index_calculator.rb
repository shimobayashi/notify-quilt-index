# お布団指数を計算するクラス
class QuiltIndexCalculator
    def self.quilt_index_and_info(outer)
      # 就寝時の室内の温度、湿度を推定する
      inner = inner_forecast_metrics(outer[:temperature], outer[:humidity])
  
      # 理想的な布団内の不快指数と就寝時の室内の不快指数の差分を計算する
      target_discomfort_index = discomfort_index(33, 55)
      inner_discomfort_index = discomfort_index(inner[:temperature], inner[:humidity])
      delta_discomfort_index = target_discomfort_index - inner_discomfort_index
  
      # お布団指数を計算する
      quilt_index = delta_discomfort_index
  
      return {
        quilt_index: quilt_index,
        outer: outer,
        inner: inner,
        suggestion: suggestion(quilt_index),
      }
    end
  
    # お布団指数からオススメの寝具を返却する
    def self.suggestion(quilt_index)
      return {
        short: suggestion_short(quilt_index),
        long: suggestion_long(quilt_index),
      }
    end
    def self.suggestion_short(quilt_index)
      quilt_index = quilt_index.to_i
      s = [
        '真夏', # ~0
        '夏', # 0~6
        '春秋', # 6~12
        '冬', # 12~18
        '真冬', # 18~
      ]
      i = [[0, (quilt_index / 6 + 1).to_i].max, s.size - 1].min
      return s[i]
    end
    def self.suggestion_long(quilt_index)
      quilt_index = quilt_index.to_i
      s = [
        '氷枕', # ～0
        'タオルケット', # 0～3
        '毛布', # 3～6
        '肌掛け布団',  # 6～9
        '肌掛け布団と毛布', # 9～12
        '合い掛け布団', # 12～15
        '合い掛け布団と毛布', # 15～18
        '肌掛け布団と合い掛け布団', # 18~21 難しい
        '肌掛け布団と合い掛け布団とタオルケット', # 21~24
        '肌掛け布団と合い掛け布団と毛布', # 24~27
        '肌掛け布団と合い掛け布団と厚手の毛布', # 27~30
        'とにかく暖かくするの', # 30～
      ]
      i1 = ((quilt_index - 1) / 3 + 1).to_i
      i2 = (quilt_index / 3 + 1).to_i
      i3 = ((quilt_index + 1) / 3 + 1).to_i
      messages = [i1, i2, i3].map{|i| [[0, i].max, s.size - 1].min}.map{|i| s[i]}
      messages = messages.uniq.join('か、')
      return messages
    end
  
    # 引数で指定された室外の数値からその時の室内の予測値を返却する
    def self.inner_forecast_metrics(temp, humd)
      # 室温を推定する
      ## 30Cなら+5C, 4Cなら+12Cになるような補正値を算出する
      ## この補正値は個人的な経験則と http://neptmh.web.fc2.com/mht015/mht015.html から適当に決めたものである
      delta = ((5 - 12) / (30 - 4).to_f)
      d_temp = delta * temp + (delta * -4) + 12
      inner_temp = temp + d_temp
  
      # 室内の相対湿度を推定する
      ## 室外の水蒸気量を算出し、そこから室内の相対湿度を推定する
      ## 一般に外気温よりも室温の方が高いため、相対湿度は低くなる
      outer_a = a(temp, humd)
      inner_a = outer_a + 2.0 # 室内の水蒸気量を雑に推定 人間とかいりゃ水蒸気量これくらい増えるだろ多分
      inner_humd = rh(inner_temp, inner_a)
  
      return {
        temperature: inner_temp,
        humidity:    inner_humd,
      }
    end
    # 以下のページにある計算式を参考に関数化した
    # http://idea.eco.coocan.jp/kousaku/k1-tsuri/seidenki/suijyouki.html
    # e=6.11×10^(7.5t/(t+237.3)
    def self.e(t)
      return 6.11 * 10 ** (7.5 * t / (t + 237.3))
    end
    # a=217×e/(t+273.15)xrh/100
    def self.a(t, rh)
      return 217 * e(t) / (t + 273.15) * rh / 100
    end
    # aの式を変形してt, aから湿度を計算する
    def self.rh(t, a)
      return ((t + 273.15) * a / (217 * e(t))) * 100
    end
  
    # 指定された数値から不快指数を返却する
    def self.discomfort_index(temp, humd)
      return 0.81 * temp + 0.01 * humd * (0.99 * temp - 14.3) + 46.3
    end
  end