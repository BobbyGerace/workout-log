import sys
import time
import curses
import pyfiglet

def parse_duration(duration_str):
    """Parse duration from MM:SS format to total seconds."""
    try:
        minutes, seconds = map(int, duration_str.split(':'))
        total_seconds = minutes * 60 + seconds
        return total_seconds
    except ValueError:
        print("Invalid duration format. Use MM:SS.")
        sys.exit(1)

def main(stdscr):
    # Initialize curses
    curses.curs_set(0)  # Hide cursor
    curses.start_color()
    curses.init_pair(1, curses.COLOR_YELLOW, curses.COLOR_BLACK)  # For "WORK"
    stdscr.nodelay(True)  # Make getch() non-blocking

    # Get duration from command-line argument or default to '00:30'
    duration_str = sys.argv[1] if len(sys.argv) > 1 else '00:30'
    total_seconds = parse_duration(duration_str)
    initial_duration = total_seconds

    while True:
        # Countdown loop
        for remaining in range(total_seconds, -1, -1):
            stdscr.clear()
            minutes = remaining // 60
            seconds = remaining % 60
            time_str = f"{minutes:02d}:{seconds:02d}"
            figlet_text = pyfiglet.figlet_format(time_str, font='univers')

            # Get screen size and calculate position for centering
            max_y, max_x = stdscr.getmaxyx()
            figlet_lines = figlet_text.split('\n')
            start_y = max_y // 2 - len(figlet_lines) // 2
            start_x = max_x // 2 - max(len(line) for line in figlet_lines) // 2

            # Display the countdown timer
            for idx, line in enumerate(figlet_lines):
                stdscr.addstr(start_y + idx, start_x, line)
            stdscr.refresh()
            time.sleep(1)

            # Allow quitting by pressing 'q'
            key = stdscr.getch()
            if key == ord('q'):
                return

        # Play ding sound
        curses.beep()

        # Display "WORK" in yellow
        stdscr.clear()
        work_text = pyfiglet.figlet_format("WORK", font='univers')
        figlet_lines = work_text.split('\n')
        max_y, max_x = stdscr.getmaxyx()
        start_y = max_y // 2 - len(figlet_lines) // 2
        start_x = max_x // 2 - max(len(line) for line in figlet_lines) // 2
        for idx, line in enumerate(figlet_lines):
            stdscr.addstr(start_y + idx, start_x, line, curses.color_pair(1))
        stdscr.refresh()

        # Wait for spacebar press to restart the countdown
        while True:
            key = stdscr.getch()
            if key == ord(' '):
                break
            elif key == ord('q'):
                return
            time.sleep(0.1)

        # Reset timer
        total_seconds = initial_duration

if __name__ == '__main__':
    curses.wrapper(main)

