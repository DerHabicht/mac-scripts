#!/bin/bash

# Constants
#   - seconds: the entire length of the timer in seconds (1500s = 25min)
#   - tick: play a 'tick' sound at this interval (in seconds)
seconds=1500
tick=30

# Empty the screen
clear

# Set Slack status
status set pom

# Remember current stderr handler, then set stderr to /dev/null
exec 3>&2
exec 2> /dev/null

# Shut off the cursor blink
tput civis

# Set timesheet and kill any running Pomodoros
timetrap sheet pom
timetrap out

# Mark the task as started in Taskwarrior
if [ "$#" -eq 1 ]
then
    task start "$1"
fi

# Set a kill flag to catch if the Pomodoro is stopped with an interrupt
killed=false

# Start the clock and play a startup sound
end=$(($(date +%s) + $seconds))
next_tick=$(($(date +%s) + $tick))

if [ "$#" -eq 1 ]
then
    timetrap in $(task _get "$1".uuid)
else
    timetrap in
fi

afplay ~/lib/mac-scripts/alerts/computerbeep_9.mp3

# Catch Ctl-C so we can gracefully exit the loop
trap 'break' INT

# Execute timer loop.
while [ "$end" -ge $(date +%s) ]
do
    # Draw the time remaining.
    # The extra spaces at the end are to ensure that any characters
    # accidentally thrown to the terminal will be overwritten on the next tick.
    echo -ne "Pomodoro: $(date -u -r $(( $end - $(date +%s) )) +%H:%M:%S)             \r"

    # Play the 'tick' sound
    if [ "$next_tick" -le `date +%s` ]
    then
        afplay ~/lib/mac-scripts/alerts/computerbeep_4.mp3
        next_tick=$((`date +%s` + $tick))
    fi

    sleep 1
done

# Reset the default Ctl-C handler
trap "export killed=true" INT

# Clear the screen
clear

# Clock out of timetrap
timetrap out

# Play finish sound indicating that we've clocked out.
afplay ~/lib/mac-scripts/alerts/alert04.mp3

# Clear Slack status
status clear

# Fire a notification dialog so we aren't dependent on the sound
echo $killed
if [ !$killed ]
then
    osascript -e 'display dialog "Time for a break." with title "Pomodoro Finished" buttons {"Dismiss"} default button "Dismiss" with icon note' > /dev/null
fi

# Restore the stderr handler
exec 2>&3

# Turn cursor blink back on
tput cnorm
