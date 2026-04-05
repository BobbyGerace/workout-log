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
end
