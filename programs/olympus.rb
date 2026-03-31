require 'json'
require_relative 'lib/util'
require_relative 'lib/workout'
require_relative 'lib/protocols'

VARS_PATH = File.join(File.dirname(__FILE__), "vars.json")

class Olympus < Workout
  CONFIG = JSON.parse(File.read(VARS_PATH)).dig("olympus")

  def initialize(day, week)
    super(day)
    @week = week
    @max = CONFIG.dig('maxes', @day)
    @reps = CONFIG.dig('reps')
    @backoffs = CONFIG.dig('backoffs')
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
    Olympus is a flexible powerbuilding program, adaptable to various phases and 
    recovery capacities. The structure provides plenty of room for recovery while
    building momentum and confidence week over week, culminating in an AMRAP on week 3.

    # Goal Weight

    Choose a goal weight you can already do for the prescribed reps, preferably
    with a rep in the tank. The program builds toward it gradually, so starting
    conservative pays off.

    # Block Structure

    Each block runs 3 working weeks plus a deload:

      Week 1: 90% of goal weight
      Week 2: 95% of goal weight
      Week 3: goal weight — go for as many reps as possible
      Week 4: deload at 80%, backoff sets only

    Backoff sets are performed at 90% of the top set weight.

    # Progressing Through Blocks

    Start with a high rep block (10 reps or so). After completing the block, you
    can either repeat it at a higher goal weight or move to a lower rep range for
    the next block. Both are valid — let recovery and goals guide the choice.

    # Backoff Sets

    The number of backoff sets can be tweaked up or down based on how recovery
    is going. If you're dragging, drop one. If you're feeling good, add one.

    # Accessories

    Accessories are run double-progression style: once you can complete all sets
    at the top of the given rep range, add weight and work back up from the bottom.

    # Running
    ```
    gym w new -t <(ruby ./programs/olympus.rb deadlift 1)
    ```

    README
  end

  def frontmatter
    <<~FRONTMATTER.strip
      ---
      name: #{day_names[@day]}
      date: #{Time.now.strftime('%A, %B %-d, %Y')}
      program: Olympus
      week: #{@week}
      training-max: #{@max}
      deload: #{%w[4 deload].include?(@week) ? "true" : "false"}
      ---

    FRONTMATTER
  end

  def exercises
    proto = Protocols::PercentageWaveLoading.new(@max, @reps, @backoffs, @week)
    case @day
    when "squat"
      [
        { key: 'squat_main',      name: 'SSB Squat',             protocol: proto },
        { key: 'squat_secondary', name: 'Romanian Deadlift',     protocol: '3x8-12' },
        { key: 'squat_accessory', name: 'Single Leg Calf Raise', protocol: '3 sets' },
      ]
    when "bench"
      [
        { key: 'bench_main',        name: 'Bench Press',         protocol: proto },
        { key: 'bench_secondary_a', name: 'Dip',                 protocol: '3x15-20' },
        { key: 'bench_secondary_b', name: 'Lat Pulldown',        protocol: '3x10-20', superset: true },
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
        { key: 'press_main',        name: 'Overhead Press',                     protocol: proto },
        { key: 'press_secondary_a', name: 'Dumbbell Bench Press',               protocol: '3x10-15' },
        { key: 'press_secondary_b', name: 'Dumbbell Row',                       protocol: '3x10-15', superset: true },
        { key: 'press_accessory_a', name: 'Barbell Overhead Triceps Extension', protocol: '3x10-20' },
        { key: 'press_accessory_b', name: 'Hammer Curl',                        protocol: '3x10-20', superset: true },
      ]
    end
  end

  private

  def exercise_overrides
    CONFIG.fetch('exercise_overrides', {})
  end
end

day = ARGV[0]
week = ARGV[1]

puts Olympus.new(day, week).to_s
