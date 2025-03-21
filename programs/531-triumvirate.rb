require 'json'

lift = ARGV[0]
week = ARGV[1]

readme = <<~README
This is a variation of 5/3/1 which emphasizes recovery
and simplicity. The assistance exercises here are 
tentative and should be changed according to weak points
and goals. Train the main lifts hard, and don't be a
hero on the assistance exercises—think like a
bodybuilder. Keep the 5/3/1 principles in mind when
running this program.

5/3/1 Principles:
- Emphasize big, multi-joint movements
- Start too light
- Progress slowly
- Break personal records
README

if lift.downcase == "readme"
  puts readme
  exit 0
end

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

# Format date like "Saturday, January 1, 2022"
frontmatter = <<~FRONTMATTER.strip
  date: #{Time.now.strftime('%A, %B %-d, %Y')}
  program: 5/3/1 FSL
  week: #{week}
  training-max: #{max}
  deload: #{week == "4" ? "true" : "false"}
FRONTMATTER

sets = <<~SETS.strip
  // #{ceil5(percentages[0] * max)}x#{reps[0]}
  // #{ceil5(percentages[1] * max)}x#{reps[1]}
  // #{ceil5(percentages[2] * max)}x#{reps[2]}
SETS

workouts = {
  "squat" => <<~SQUAT,
    ---
    name: Squat
    #{frontmatter}
    ---

    # Front Squat
    #{sets}
    
    # Good Morning
    // 5x10

    # Walking Lunge
    // 3-5 sets

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

    # Dumbbell Bench Press
    // 5x10

    # Dumbbell Row
    // 5x10

    # Barbell Curl
    // 3x20
  BENCH
  "deadlift" => <<~DEADLIFT,
    ---
    name: Deadlift
    #{frontmatter}
    ---

    # Deadlift
    #{sets}
kkk
    # Bulgarian Split Squat
    // 5x10

    # Hanging Leg Raise
    // 5x10

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

    # Chin-Up
    // 5x5-12

    # Lateral Raise
    // 3x20
  PRESS
}

puts workouts[lift]
