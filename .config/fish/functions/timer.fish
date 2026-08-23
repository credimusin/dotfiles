function timer --description "Set a timer in minutes (default) or specify s/m/h"
    if test (count $argv) -lt 1
        echo "Usage: timer <time>[s|m|h] [message]"
        return 1
    end

    set -l input $argv[1]
    set -l value ""
    set -l unit ""

    # Parse value and unit
    if string match -qr '^([0-9]+(\.[0-9]+)?)([smh]?)$' -- $input
        set value (string replace -r '^([0-9]+(\.[0-9]+)?)([smh]?)$' '$1' -- $input)
        set unit (string replace -r '^([0-9]+(\.[0-9]+)?)([smh]?)$' '$3' -- $input)
    else
        echo "Error: Invalid time format. Examples: 10, 1.5, 30s, 5m, 2h"
        return 1
    end

    # Calculate multiplier
    set -l multiplier 60 # default is minutes
    if test "$unit" = "s"
        set multiplier 1
    else if test "$unit" = "h"
        set multiplier 3600
    else if test "$unit" = "m"
        set multiplier 60
    end

    set -l seconds (math "$value * $multiplier")

    set -l message "Time is up!"
    if test (count $argv) -ge 2
        set message $argv[2..-1]
    end

    # Format the unit string for notification display
    set -l unit_str "minutes"
    if test "$unit" = "s"
        set unit_str "seconds"
    else if test "$unit" = "h"
        set unit_str "hours"
    end

    # Call the timer-notify script in the background
    nohup timer-notify "$seconds" "$value $unit_str" "$message" >/dev/null 2>&1 &
    
    echo "Timer set for $value $unit_str ($seconds seconds) in the background. (PID: $last_pid)"
end
