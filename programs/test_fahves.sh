#!/bin/bash

# --- Configuration ---
RUBY_SCRIPT="fahves.rb"
SNAPSHOT_DIR="snapshots"
LIFTS=("squat" "bench" "deadlift" "press")
WEEKS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "deload")

# Ensure snapshot directory exists
mkdir -p "$SNAPSHOT_DIR"

# Function to run the command and scrub the dynamic date line
run_and_scrub() {
    # 1. Run the ruby script and save to a temporary variable
    # 2. Use 'printf' to handle potential trailing newlines correctly
    # 3. Remove the 2>/dev/null so we can actually see if Ruby is screaming
    local raw_output
    raw_output=$(ruby "$RUBY_SCRIPT" "$1" "$2")
    
    # Check if the command actually succeeded
    if [ $? -ne 0 ]; then
        echo "ERROR: Ruby script failed for $1 $2" >&2
        return 1
    fi

    # Scrub the date and return
    echo "$raw_output" | sed 's/^date: .*/date: <MOCKED_DATE>/'
}

echo "--- Running Fahves Regression Suite ---"

# 1. Test regular lift/week combinations
for lift in "${LIFTS[@]}"; do
    for week in "${WEEKS[@]}"; do
        snapshot_file="${SNAPSHOT_DIR}/${lift}_week_${week}.txt"
        current_output=$(run_and_scrub "$lift" "$week")

        if [ ! -f "$snapshot_file" ]; then
            echo "[NEW] Creating snapshot: $lift (Week $week)"
            echo "$current_output" > "$snapshot_file"
        else
            if echo "$current_output" | diff -u "$snapshot_file" - > /dev/null; then
                echo "[PASS] $lift (Week $week)"
            else
                echo "[FAIL] $lift (Week $week) - Regression detected!"
                echo "------------------------------------------------------------"
                echo "$current_output" | diff -u "$snapshot_file" -
                echo "------------------------------------------------------------"
                exit 1
            fi
        fi
    done
done

# 2. Test README output
readme_snapshot="${SNAPSHOT_DIR}/readme.txt"
readme_output=$(run_and_scrub "readme" "1")

if [ ! -f "$readme_snapshot" ]; then
    echo "[NEW] Creating snapshot: README"
    echo "$readme_output" > "$readme_snapshot"
else
    if echo "$readme_output" | diff -u "$readme_snapshot" - > /dev/null; then
        echo "[PASS] README"
    else
        echo "[FAIL] README - Regression detected!"
        exit 1
    fi
fi

echo "--- All tests passed successfully! ---"
