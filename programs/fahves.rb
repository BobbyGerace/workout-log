require 'json'

module Fahves
  VARS_PATH = File.join(File.dirname(__FILE__), "vars.json")
  CONFIG = JSON.parse(File.read(VARS_PATH)).dig("fahves")
  BACKOFF_SETS_INIT = 2

  class WorkoutBuilder
  def initialize(overrides: {}, metadata: {})
    @overrides = overrides
    @metadata = metadata # Ruby 1.9+ preserves insertion order
    @exercises = []
  end

  def add_exercise(key, default_name, protocol, superset: false)
    name = @overrides[key] || default_name
    prefix = superset ? '&' : '#'
    
    # Standardizing the protocol format across all programs
    formatted_proto = protocol.to_s.split("\n").map { |line| "// #{line}" }.join("\n")
    
    @exercises << "#{prefix} #{name}\n#{formatted_proto}"
    self
  end

  def render
    [render_frontmatter, @exercises.join("\n\n")].join("\n\n")
  end

  private

  def render_frontmatter
    lines = ["---"]
    
    @metadata.each do |k, v|
      # Automatically format if it's a Time object, otherwise use as-is
      val = v.is_a?(Time) ? v.strftime('%A, %B %-d, %Y') : v
      lines << "#{k}: #{val}"
    end
    
    lines << "---"
    lines.join("\n")
  end
end

  # --- Domain Logic (Specific to Fahves) ---
  class MainLiftProtocol
    PERCENTAGES = {
      "deload" => [0.65],
      "1" => [0.75], "2" => [0.75, 0.8], "3" => [0.75, 0.8, 0.85],
      "4" => [0.8], "5" => [0.8, 0.85], "6" => [0.8, 0.85, 0.9],
      "7" => [0.9, 0.8], "8" => [0.95, 0.85], "9" => [1.0, 0.9]
    }

    def initialize(training_max, week)
      @training_max = training_max
      @week = week
    end

    def to_s
      return deload if @week == "deload"
      %w[7 8 9].include?(@week) ? intensity : volume
    end

    private

    def volume
      num_sets = (@week.to_i - 1) % 3 + 3
      weight_range = PERCENTAGES[@week].map { |p| ceil5(p * @training_max) }.join(' - ')
      sets = Array.new(num_sets, '5').join(',')
      "#{weight_range}x#{sets}"
    end

    def intensity
      num_backoff_sets = [BACKOFF_SETS_INIT - (@week.to_i - 1) % 3, 0].max
      top_weight = ceil5(PERCENTAGES[@week][0] * @training_max)
      backoff_weight = ceil5(PERCENTAGES[@week][1] * @training_max)

      sets = "#{top_weight}x5"
      sets += "+" if @week == "9"
      sets += "\n#{backoff_weight}x#{Array.new(num_backoff_sets, "5").join(',')}" if num_backoff_sets > 0
      sets
    end

    def deload
      weight = ceil5(PERCENTAGES["deload"][0] * @training_max)
      "#{weight}x5,5"
    end

    def ceil5(num)
      (num / 5.0).ceil * 5
    end
  end

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
end

# --- Script Execution ---
lift = ARGV[0]&.downcase
week = ARGV[1]

if lift == "readme"
  puts Fahves::README
  exit
end

# 1. Prepare Data for the Builder
max = Fahves::CONFIG.dig("maxes", lift)
name_map = { "squat" => "Squat", "bench" => "Bench Press", "deadlift" => "Deadlift", "press" => "Overhead Press" }

# The Hash order here determines the output order
metadata = {
  "name"         => name_map[lift],
  "date"         => Time.now, # Builder will auto-format this
  "program"      => "Fahves",
  "week"         => week,
  "training-max" => max,
  "deload"       => (week == "deload" ? "true" : "false")
}

# 2. Initialize Generic Builder
builder = Fahves::WorkoutBuilder.new(
  overrides: Fahves::CONFIG.dig("exercise_overrides") || {},
  metadata: metadata
)

# 3. Handle Program Structure
protocol = Fahves::MainLiftProtocol.new(max, week)

case lift
when "squat"
  builder.add_exercise('squat_main', 'Front Squat', protocol)
         .add_exercise('squat_secondary', 'Romanian Deadlift', '3x8-12')
         .add_exercise('squat_accessory', 'Single Leg Calf Raise', '3 sets')
when "bench"
  builder.add_exercise('bench_main', 'Bench Press', protocol)
         .add_exercise('bench_secondary_a', 'Dumbbell Fly', '3x15-20')
         .add_exercise('bench_secondary_b', 'Inverted Row', '3x10-20', superset: true)
         .add_exercise('bench_accessory_a', 'Incline Curl', '3x10-20')
         .add_exercise('bench_accessory_b', 'Lateral Raise', '3x10-20', superset: true)
when "deadlift"
  builder.add_exercise('deadlift_main', 'Deadlift', protocol)
         .add_exercise('deadlift_secondary', 'Bulgarian Split Squat', '3x8-12')
         .add_exercise('deadlift_accessory_a', 'Single Leg Calf Raise', '3 sets')
         .add_exercise('deadlift_accessory_b', 'Hanging Leg Raise', '3x10', superset: true)
when "press"
  builder.add_exercise('press_main', 'Overhead Press', protocol)
         .add_exercise('press_secondary_a', 'Dumbbell Bench Press', '3x10-15')
         .add_exercise('press_secondary_b', 'Lat Pulldown', '3x10-15', superset: true)
         .add_exercise('press_accessory_a', 'Lateral Raise', '3x10-20')
         .add_exercise('press_accessory_b', 'Hammer Curl', '3x10-20', superset: true)
else
  abort "Invalid lift name"
end

puts builder.render
