require 'json'

module Fahves
  # TODO: Maybe make this configurable
  BACKOFF_SETS_INIT = 2
  VARS_PATH = File.join(File.dirname(__FILE__), "vars.json") 
  CONFIG = JSON.parse(File.read(VARS_PATH)).dig("fahves")

  README = <<~README
  This is a powerbuilding program built around a progression of fives. It
  is broken up into three blocks-Two volume blocks and one intensity blocks.

  # Volume Blocks

  The two volume blocks are structured as three week waves, beginning as an 3x5 and
  adding sets and weight until the final week is a hard 5x5.

  The second Volume block is similar to the first, but begins and ends at a slightly higher weight.

  A range of weights is provided for weeks two and three, allowing the lifter to
  autoregulate. Furthermore, the sets don't all have to be the same. You can work up
  to or back away from heavier weights as necessary during the workout.

  # Intensity Block

  As you might expect, the intensity block contrasts with the volume block by reducing volume
  and increasing intensity. This is accomplished by switching to a top-set / back-off 
  progression. The number of backoff sets will reduce each week to reduce fatigue and facilitate
  a PR on week three.

  On week three, go for as many reps as possible. You should be hitting at least 5 here.

  # Training Max

  The training max should be roughly equivalent to a 5RM. As always, it's better to be conservative
  here and increase slowly, rather than to miss reps at the end of the program.

  # Deloads

  A deload week can be taken at the end of any block by passing in "deload" instead of the week number.

  # Running 
  ```
  gym w new -t <(ruby ./programs/fahves.rb deadlift 3)
  ```

  README

  class Workout
    def initialize(lift, week) 
      @lift = lift
      @week = week
      @max = CONFIG.dig('maxes', @lift)
    end

    def to_s
      return README if @lift.downcase == "readme"

      raise "Invalid lift name" unless exercise_definition.include?(@lift)

      frontmatter + "\n\n" + exercise_definition[@lift].map(&:to_s).join
    end
    
    def main_lift_protocol
      MainLiftProtocol.new(@max, @week)
    end

    def exercise_definition
      {
        "squat" => [
          Exercise.new('squat_main', 'Front Squat', main_lift_protocol),
          Exercise.new('squat_secondary', 'Romanian Deadlift', '3x8-12'),
          Exercise.new('squat_accessory', 'Single Leg Calf Raise', '3 sets'),
        ],

        "bench" => [
          Exercise.new('bench_main', 'Bench Press', main_lift_protocol),
          Exercise.new('bench_secondary_a', 'Dumbbell Fly', '3x15-20'),
          Exercise.new('bench_secondary_b', 'Inverted Row', '3x10-20', true),
          Exercise.new('bench_accessory_a', 'Incline Curl', '3x10-20'),
          Exercise.new('bench_accessory_b', 'Lateral Raise', '3x10-20', true),
        ],

        "deadlift" => [
          Exercise.new('deadlift_main', 'Deadlift', main_lift_protocol),
          Exercise.new('deadlift_secondary', 'Bulgarian Split Squat', '3x8-12'),
          Exercise.new('deadlift_accessory_a', 'Single Leg Calf Raise', '3 sets'),
          Exercise.new('deadlift_accessory_b', 'Hanging Leg Raise', '3x10', true),
        ],

        "press" => [
          Exercise.new('press_main', 'Overhead Press', main_lift_protocol),
          Exercise.new('press_secondary_a', 'Dumbbell Bench Press', '3x10-15'),
          Exercise.new('press_secondary_b', 'Lat Pulldown', '3x10-15', true),
          Exercise.new('press_accessory_a', 'Lateral Raise', '3x10-20'),
          Exercise.new('press_accessory_b', 'Hammer Curl', '3x10-20', true),
        ]
      }
    end

    def name_def
      { "squat" => "Squat", "bench" => "Bench Press", "deadlift" => "Deadlift", "press" => "Overhead Press" }
    end

    def frontmatter
      # Format date like "Saturday, January 1, 2022"
      <<~FRONTMATTER.strip
        ---
        name: #{name_def[@lift]}
        date: #{Time.now.strftime('%A, %B %-d, %Y')}
        program: Fahves
        week: #{@week}
        training-max: #{@max}
        deload: #{@week == "deload" ? "true" : "false"}
        ---

      FRONTMATTER
    end
  end

  class Exercise
    def initialize(key, default, protocol, superset = false)
      @key = key
      @default = default
      @protocol = protocol
      @superset = superset
    end

    def exercise_name
      CONFIG.dig("exercise_overrides", @key) || @default
    end

    def line_start
      @superset ? '&' : '#'
    end

    def protocol
      # Add comments to beginnings of every line
      @protocol.to_s.split("\n").map do |line|
        '// ' + line
      end.join("\n")
    end

    def to_s
      "#{line_start} #{exercise_name}\n#{protocol}\n\n"
    end
  end

  class MainLiftProtocol
    PERCENTAGES = {
      "deload" => [0.65],
      # volume block 1
      "1" => [0.75],
      "2" => [0.75, 0.8],
      "3" => [0.75, 0.8, 0.85],
      # volume block 2
      "4" => [0.8],
      "5" => [0.8, 0.85],
      "6" => [0.8, 0.85, 0.9],
      # intensity block
      "7" => [0.9, 0.8],
      "8" => [0.95, 0.85],
      "9" => [1, 0.9],
    }

    def initialize(training_max, week)
      @training_max = training_max
      @week = week
      raise "Invalid week number" if percentages.nil?
    end

    def percentages
      PERCENTAGES[@week]
    end

    def volume
      num_sets = (@week.to_i - 1) % 3 + 3
      weight_range = percentages.map { |p| ceil5(p * @training_max) }.join(' - ')
      sets = Array.new(num_sets, '5').join(',')

      "#{weight_range}x#{sets}"
    end

    def intensity
      num_backoff_sets = [BACKOFF_SETS_INIT - (@week.to_i - 1) % 3, 0].max
      top_weight = ceil5(percentages[0] * @training_max)
      backoff_weight = ceil5(percentages[1] * @training_max)

      sets = "#{top_weight}x5"
      sets += "+" if @week == "9"
      sets += "\n#{backoff_weight}x#{Array.new(num_backoff_sets, "5").join(',')}" if num_backoff_sets > 0

      sets
    end

    def deload
      weight = ceil5(percentages[0] * @training_max)
      "#{weight}x5,5"
    end

    def to_s
      sets = if %w[1 2 3 4 5 6].include?(@week)
        volume
      elsif  %w[7 8 9].include?(@week)
        intensity
      else
        deload
      end
    end

    def ceil5(num)
      (num / 5.0).ceil * 5
    end
  end
end

lift = ARGV[0]
week = ARGV[1]

workout = Fahves::Workout.new(lift, week)
puts workout.to_s
