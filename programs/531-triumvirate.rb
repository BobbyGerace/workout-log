require 'json'
require_relative 'lib/util'
require_relative 'lib/workout'
require_relative 'lib/protocols'

VARS_PATH = File.join(File.dirname(__FILE__), "vars.json")

class Triumvirate < Workout
  CONFIG = JSON.parse(File.read(VARS_PATH)).dig("531")

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
    5/3/1 Triumvirate is a variation of Jim Wendler's 5/3/1 that emphasizes
    recovery and simplicity. Each training day pairs the main lift with two
    assistance exercises, keeping total volume manageable so you can push
    the main lift hard every session.

    # Main Lift

    The main lift follows the classic 5/3/1 wave across four weeks:

      Week 1: 3 sets × 5 reps   (65%, 75%, 85%)
      Week 2: 3 sets × 3 reps   (70%, 80%, 90%)
      Week 3: 5/3/1             (75%, 85%, 95%)
      Week 4: Deload            (40%, 50%, 60%)

    The top set of each working week is performed for as many reps as possible.
    This is where progress is made — don't leave reps in the tank. Log your
    rep PR and try to beat it next cycle.

    # Training Max

    Use 90% of your true 1RM as the training max — not your actual max. Starting
    light is not optional; it's the mechanism. Rushing the training max leads to
    stalled progress and missed reps. Add 5 lbs to upper body lifts and 10 lbs to
    lower body lifts after each completed 4-week cycle.

    # Assistance Work

    The two assistance exercises are suggestions. Swap them based on weak points
    and goals. Think like a bodybuilder here — controlled reps, moderate weight,
    no grinding. Keep one push and one pull per session where possible.

    # 5/3/1 Principles
    - Emphasize big, multi-joint movements
    - Start too light
    - Progress slowly
    - Break personal records

    # Running
    ```
    gym w new -t <(ruby ./programs/531-triumvirate.rb deadlift 2)
    ```
    README
  end

  def frontmatter
    <<~FRONTMATTER.strip
      ---
      name: #{day_names[@day]}
      date: #{Time.now.strftime('%A, %B %-d, %Y')}
      program: 5/3/1 Triumvirate
      week: #{@week}
      training-max: #{@max}
      deload: #{@week == "4" ? "true" : "false"}
      ---

    FRONTMATTER
  end

  def exercises
    proto = Protocols::FiveThreeOneProtocol.new(@max, @week)
    case @day
    when "squat"
      [
        { key: 'squat_main',         name: 'SSB Squat',           protocol: proto },
        { key: 'squat_secondary',    name: 'Romanian Deadlift',     protocol: '5x10' },
        { key: 'squat_accessory',    name: 'Single Leg Calf Raise', protocol: '3 sets' },
        { key: 'squat_conditioning', name: 'Conditioning',          protocol: 'pick something hard and do it for 10-15 min' },
      ]
    when "bench"
      [
        { key: 'bench_main',        name: 'Bench Press',                         protocol: proto },
        { key: 'bench_secondary_a', name: 'Dumbbell Incline Bench',              protocol: '5x10' },
        { key: 'bench_secondary_b', name: 'Inverted Row',                        protocol: '5x10', superset: true },
        { key: 'bench_accessory_a', name: 'Dumbbell Curl',                       protocol: '3x20' },
        { key: 'bench_accessory_b', name: 'Dumbbell Overhead Triceps Extension', protocol: '3x10-20', superset: true },
      ]
    when "deadlift"
      [
        { key: 'deadlift_main',         name: 'Deadlift',              protocol: proto },
        { key: 'deadlift_secondary',    name: 'Bulgarian Split Squat', protocol: '5x10' },
        { key: 'deadlift_accessory_a',  name: 'Single Leg Calf Raise', protocol: '3x10' },
        { key: 'deadlift_accessory_b',  name: 'Hanging Leg Raise',     protocol: '3x10', superset: true },
        { key: 'deadlift_conditioning', name: 'Conditioning',          protocol: 'pick something hard and do it for 10-15 min' },
      ]
    when "press"
      [
        { key: 'press_main',        name: 'Overhead Press',      protocol: proto },
        { key: 'press_secondary_a', name: 'Dip', protocol: '5x10-15' },
        { key: 'press_secondary_b', name: 'T-bar Row',            protocol: '5x5-12' },
        { key: 'press_accessory_a', name: 'Lateral Raise',        protocol: '3x20' },
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

puts Triumvirate.new(lift, week).to_s
