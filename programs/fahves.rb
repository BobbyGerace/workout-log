require 'json'

lift = ARGV[0]
week = ARGV[1]

# TODO: Maybe make this configurable
BACKOFF_SETS_INIT = 2

readme = <<~README
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

if lift.downcase == "readme"
  puts readme
  exit 0
end

percentages = {
  "deload" => [0.65],
  # volume block 1
  "1" => [0.75],
  "2" => [0.75, 0.8],
  "3" => [0.75, 0.85],
  # volume block 2
  "4" => [0.8],
  "5" => [0.8, 0.85],
  "6" => [0.8, 0.9],
  # intensity block
  "7" => [0.9, 0.8],
  "8" => [0.95, 0.9 ],
  "9" => [1, 0.95],
}[week]

raise "Invalid week number" if percentages.nil?

vars_path = File.join(File.dirname(__FILE__), "vars.json")
max = JSON.parse(File.read(vars_path)).dig("fahves", "maxes", lift).to_i

def ceil5(num)
  (num / 5.0).ceil * 5
end

# Format date like "Saturday, January 1, 2022"
frontmatter = <<~FRONTMATTER.strip
  date: #{Time.now.strftime('%A, %B %-d, %Y')}
  program: Fahves
  week: #{week}
  training-max: #{max}
  deload: #{week == "deload" ? "true" : "false"}
FRONTMATTER

sets = if %w[1 2 3 4 5 6].include?(week)
  # volume blocks
  num_sets = (week.to_i - 1) % 3 + 3
  init_weight = ceil5(percentages[0] * max)
  top_weight = percentages[1] ? ceil5(percentages[1] * max) : nil
  weight_range = top_weight.nil? ? init_weight.to_s : "#{init_weight} - #{top_weight}"
  sets = Array.new(num_sets, '5').join(',')

  "// #{weight_range}x#{sets}"
elsif  %w[7 8 9].include?(week)
  # intensity block
  num_backoff_sets = [BACKOFF_SETS_INIT - (week.to_i - 1) % 3, 0].max
  top_weight = ceil5(percentages[0] * max)
  backoff_weight = ceil5(percentages[1] * max)

  sets = "// #{top_weight}x5"
  sets += "+" if week == "9"
  sets += "\n// #{backoff_weight}x#{Array.new(num_backoff_sets, "5").join(',')}" if num_backoff_sets > 0

  sets
else
  # deload week
  weight = ceil5(percentages[0] * max)
  "// #{weight}x5,5"
end

workouts = {
  "squat" => <<~SQUAT,
    ---
    name: Squat
    #{frontmatter}
    ---

    # Front Squat
    #{sets}
    
    # Romanian Deadlift
    // 3x8-12

    # Single Leg Calf Raise
    // 3 sets
  SQUAT
  "bench" => <<~BENCH,
    ---
    name: Bench Press
    #{frontmatter}
    ---

    # Bench Press
    #{sets}

    # Dumbbell Fly
    // 3x15-20

    & Inverted Row
    // 3x10-20

    # Incline Curl
    // 3x10-20

    & Lateral Raise
    // 3x10-20
  BENCH
  "deadlift" => <<~DEADLIFT,
    ---
    name: Deadlift
    #{frontmatter}
    ---

    # Deadlift
    #{sets}

    # Bulgarian Split Squat
    // 3x8-12

    # Single Leg Calf Raise
    // 3 sets

    & Hanging Leg Raise
    // 3x10
  DEADLIFT
  "press" => <<~PRESS,
    ---
    name: Overhead Press
    #{frontmatter}
    ---

    # Overhead Press
    #{sets}

    # Dumbbell Bench Press
    // 3x10-15

    # Lat Pulldown
    // 3x10-15

    # Lateral Raise
    // 3x10-20

    & Hammer Curl
    // 3x10-20
  PRESS
}

raise "Invalid lift name" unless workouts.include?(lift)

puts workouts[lift]
