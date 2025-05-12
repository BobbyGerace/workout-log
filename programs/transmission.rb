require 'json'

lift = ARGV[0]
week = ARGV[1]

readme = <<~README
TODO
README

if lift.downcase == "readme"
  puts readme
  exit 0
end

START_PERCENT = 70
INCREMENT = 2.5

# TODO: handle deload week
percentage = START_PERCENT + (week.to_i - 1) + INCREMENT

vars_path = File.join(File.dirname(__FILE__), "vars.json")
max = JSON.parse(File.read(vars_path)).dig("transmission", "maxes", lift).to_i

def ceil5(num)
  (num / 5.0).ceil * 5
end

# Format date like "Saturday, January 1, 2022"
frontmatter = <<~FRONTMATTER.strip
  date: #{Time.now.strftime('%A, %B %-d, %Y')}
  program: Transmission
  week: #{week}
  percentage: #{percentage}
  training-max: #{max}
  deload: #{week == "deload" ? "true" : "false"}
FRONTMATTER

sets = <<~SETS.strip
  // 5x5, 4x4, 3x3, 2x2, or 1x1
  // #{ceil5(max * percentage / 100)}x
SETS

workouts = {
  "squat" => <<~SQUAT,
    ---
    name: Squat
    #{frontmatter}
    ---

    # SSB Squat
    #{sets}
    
    # Romanian Deadlift
    // 3x6-10

    # Single Leg Calf Raise
    // 3 sets

    # Conditioning
    // pick something hard and do it for 10-15 min
  SQUAT
  "bench" => <<~BENCH,
    ---
    name: Bench Press
    #{frontmatter}
    ---

    # Bench Press
    #{sets}

    # Dumbbell Incline Bench
    // 5x10

    # Inverted Row
    // 5x10

    # Dumbbell Curl
    // 3x20
  BENCH
  "deadlift" => <<~DEADLIFT,
    ---
    name: Deadlift
    #{frontmatter}
    ---

    # Deadlift
    #{sets}

    # Bulgarian Split Squat
    // 5x10

    # Single Leg Calf Raise
    // 3x10

    & Hanging Leg Raise
    // 3x10

    # Conditioning
    // pick something hard and do it for 10-15 min
  DEADLIFT
  "press" => <<~PRESS,
    ---
    name: Overhead Press
    #{frontmatter}
    ---

    # Overhead Press
    #{sets}

    # Dip
    // 5x10-15

    # T-bar Row
    // 5x5-12

    # Lateral Raise
    // 3x20
  PRESS
}

puts workouts[lift]
