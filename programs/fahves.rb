require 'json'

VARS_PATH = File.join(File.dirname(__FILE__), "vars.json")

class Workout
  def initialize(day)
    @day = day
  end

  def to_s
    return readme if @day.downcase == "readme"
    raise "Invalid day" unless day_names.key?(@day)
    frontmatter + "\n\n" + exercises.map { |e| format_exercise(e) }.join
  end

  def day_names
    raise NotImplementedError
  end

  def frontmatter
    raise NotImplementedError
  end

  def exercises
    raise NotImplementedError
  end

  def readme
    "No readme defined"
  end

  private

  def exercise_overrides
    {}
  end

  def format_exercise(exercise)
    name = exercise_overrides[exercise[:key]] || exercise[:name]
    prefix = exercise[:superset] ? '&' : '#'
    lines = exercise[:protocol].to_s.split("\n").map { |l| '// ' + l }.join("\n")
    "#{prefix} #{name}\n#{lines}\n\n"
  end
end

class MainLiftProtocol
  BACKOFF_SETS_INIT = 2

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
    if %w[1 2 3 4 5 6].include?(@week)
      volume
    elsif %w[7 8 9].include?(@week)
      intensity
    else
      deload
    end
  end

  def ceil5(num)
    (num / 5.0).ceil * 5
  end
end

class Fahves < Workout
  CONFIG = JSON.parse(File.read(VARS_PATH)).dig("fahves")

  def initialize(day, week)
    super(day)
    @week = week
    @max = CONFIG.dig('maxes', @day)
  end

  def day_names
    {
      "squat"    => "Squat",
      "bench"    => "Bench Press",
      "deadlift" => "Deadlift",
      "press"    => "Overhead Press",
    }
  end

  def readme
    <<~README
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

  def frontmatter
    <<~FRONTMATTER.strip
      ---
      name: #{day_names[@day]}
      date: #{Time.now.strftime('%A, %B %-d, %Y')}
      program: Fahves
      week: #{@week}
      training-max: #{@max}
      deload: #{@week == "deload" ? "true" : "false"}
      ---

    FRONTMATTER
  end

  def exercises
    proto = MainLiftProtocol.new(@max, @week)
    case @day
    when "squat"
      [
        { key: 'squat_main',      name: 'Front Squat',           protocol: proto },
        { key: 'squat_secondary', name: 'Romanian Deadlift',     protocol: '3x8-12' },
        { key: 'squat_accessory', name: 'Single Leg Calf Raise', protocol: '3 sets' },
      ]
    when "bench"
      [
        { key: 'bench_main',        name: 'Bench Press',         protocol: proto },
        { key: 'bench_secondary_a', name: 'Dumbbell Fly',        protocol: '3x15-20' },
        { key: 'bench_secondary_b', name: 'Inverted Row',        protocol: '3x10-20', superset: true },
        { key: 'bench_accessory_a', name: 'Incline Curl',        protocol: '3x10-20' },
        { key: 'bench_accessory_b', name: 'Lateral Raise',       protocol: '3x10-20', superset: true },
      ]
    when "deadlift"
      [
        { key: 'deadlift_main',        name: 'Deadlift',              protocol: proto },
        { key: 'deadlift_secondary',   name: 'Bulgarian Split Squat', protocol: '3x8-12' },
        { key: 'deadlift_accessory_a', name: 'Single Leg Calf Raise', protocol: '3 sets' },
        { key: 'deadlift_accessory_b', name: 'Hanging Leg Raise',     protocol: '3x10', superset: true },
      ]
    when "press"
      [
        { key: 'press_main',        name: 'Overhead Press',       protocol: proto },
        { key: 'press_secondary_a', name: 'Dumbbell Bench Press', protocol: '3x10-15' },
        { key: 'press_secondary_b', name: 'Lat Pulldown',         protocol: '3x10-15', superset: true },
        { key: 'press_accessory_a', name: 'Lateral Raise',        protocol: '3x10-20' },
        { key: 'press_accessory_b', name: 'Hammer Curl',          protocol: '3x10-20', superset: true },
      ]
    end
  end

  private

  def exercise_overrides
    CONFIG.fetch('exercise_overrides', {})
  end
end

lift = ARGV[0]
week = ARGV[1]

puts Fahves.new(lift, week).to_s
