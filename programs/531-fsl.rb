require 'json'

lift = ARGV[0]
week = ARGV[1]

percentages = {
  "1" => [0.65, 0.75, 0.85],
  "2" => [0.70, 0.80, 0.90],
  "3" => [0.75, 0.85, 0.95],
  "4" => [0.40, 0.50, 0.60],
}[week]

reps = {
  "1" => [5, 5, 5],
  "2" => [3, 3, 3],
  "3" => [5, 3, 1],
  "4" => [5, 5, 5],
}[week]

vars_path = File.join(File.dirname(__FILE__), "vars.json")
max = JSON.parse(File.read(vars_path)).dig("531", "maxes", lift).to_i

def ceil5(num)
  (num / 5.0).ceil * 5
end

frontmatter = <<~FRONTMATTER.strip
  date: #{Time.now.strftime('%Y-%m-%d')}
  program: 5/3/1 FSL
  week: #{week}
  training-max: #{max}
  deload: #{week == "4" ? "true" : "false"}
FRONTMATTER

sets = <<~SETS.strip
  // #{ceil5(percentages[0] * max)}x#{reps[0]}
  // #{ceil5(percentages[1] * max)}x#{reps[1]}
  // #{ceil5(percentages[2] * max)}x#{reps[2]}
  // #{ceil5(percentages[0] * max)}x5,5,5,5,5
SETS

workouts = {
  "squat" => <<~SQUAT,
    ---
    name: Squat
    #{frontmatter}
    ---

    # Front Squat
    #{sets}
    
    # Romanian Deadlift
    // ?x8-12

    # Single Leg Calf Raise
    // ?x15-20

    & Face Pull
    // ?x15-20
  SQUAT
  "bench" => <<~BENCH,
    ---
    name: Bench Press
    #{frontmatter}
    ---

    # Bench Press
    #{sets}

    # Dumbbell Overhead Press
    // ?x10-15

    & Dumbbell Row
    // ?x10-15

    # Barbell Curl
    // ?x10-15

    & Barbell Overhead Triceps Extension
    // ?x10-15
  BENCH
  "deadlift" => <<~DEADLIFT,
    ---
    name: Deadlift
    #{frontmatter}
    ---

    # Deadlift
    #{sets}

    # SSB Squat
    // ?x8-12 3 sets

    # Single Leg Calf Raise
    // ?x15-20 3 sets

    & Band Pull-Apart
    // { band: ? } 3 sets
  DEADLIFT
  "press" => <<~PRESS,
    ---
    name: Overhead Press
    #{frontmatter}
    ---

    # Overhead Press
    #{sets}

    # Dumbbell Bench Press
    // ?x10-15

    & Chin-Up
    // ?x5-12

    # Hammer Curl
    // ?x10-15

    & Dumbbell Overhead Triceps Extension
    // ?10-15
  PRESS
}

puts workouts[lift]
