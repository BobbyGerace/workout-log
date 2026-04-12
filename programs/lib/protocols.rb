require_relative 'util'

module Protocols
  class PercentageWaveLoading
    TOP_PERCENTAGES = {
      "1" => 0.90,
      "2" => 0.95,
      "3" => 1.00,
    }

    def initialize(goal_weight, reps, backoffs, week)
      @goal_weight = goal_weight
      @reps = reps
      @backoffs = backoffs
      @week = week
    end

    def to_s
      if @week == "4" || @week == "deload"
        reps = (@reps * 0.67).floor
        weight = Util.ceil5(@goal_weight * 0.80)
        "#{weight}x#{Array.new(@backoffs, reps).join(',')}"
      else
        top = Util.ceil5(@goal_weight * TOP_PERCENTAGES[@week])
        plus = @week == "3" ? '+' : ''
        backoff = Util.ceil5(top * 0.90)
        sets = Array.new(@backoffs, @reps).join(',')
        "#{top}x#{@reps}#{plus}\n#{backoff}x#{sets}"
      end
    end
  end

  class FiveThreeOneProtocol
    PERCENTAGES = {
      "1" => [0.65, 0.75, 0.85],
      "2" => [0.70, 0.80, 0.90],
      "3" => [0.75, 0.85, 0.95],
      "4" => [0.40, 0.50, 0.60],
    }

    REPS = {
      "1" => [5, 5, 5],
      "2" => [3, 3, 3],
      "3" => [5, 3, 1],
      "4" => [5, 5, 5],
    }

    def initialize(training_max, week)
      @training_max = training_max
      @week = week
      raise "Invalid week number" if PERCENTAGES[@week].nil?
    end

    def to_s
      PERCENTAGES[@week].zip(REPS[@week]).map.with_index do |(pct, rep), i|
        weight = Util.ceil5(pct * @training_max)
        amrap = (@week != "4" && i == 2) ? '+' : ''
        "#{weight}x#{rep}#{amrap}"
      end.join("\n")
    end
  end
end
