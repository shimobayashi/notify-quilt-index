require_relative 'quilt_index_calculator'

puts QuiltIndexCalculator.discomfort_index(33, 55)
puts QuiltIndexCalculator.discomfort_index(21.6, 43) # 71.76になるかと思っていたが、66.84が正しかった
puts QuiltIndexCalculator.discomfort_index(27, 55)
