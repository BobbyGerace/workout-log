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
