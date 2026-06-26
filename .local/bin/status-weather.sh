#!/bin/bash
# Status script for Weather & Time (Saint Petersburg, Russia)

# Fetch weather (Explicitly Saint-Petersburg, Russia - max 3s timeout)
RESPONSE=$(curl -s --max-time 3 "wttr.in/Saint-Petersburg,Russia?format=%C|%t" 2>/dev/null)

# Verify the response is valid (must contain the temperature symbol °C)
if [ -z "$RESPONSE" ] || [[ "$RESPONSE" != *"°C"* ]]; then
    WEATHER="  No connection to wttr.in"
else
    # Parse description and temperature
    IFS='|' read -r WEATHER_DESC WEATHER_TEMP <<< "$RESPONSE"
    
    # Map description to a clean Nerd Font weather icon
    DESC_LOWER=$(echo "$WEATHER_DESC" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$DESC_LOWER" =~ "clear" || "$DESC_LOWER" =~ "sunny" ]]; then
        W_ICON="" # Sun / Clear
    elif [[ "$DESC_LOWER" =~ "rain" || "$DESC_LOWER" =~ "drizzle" || "$DESC_LOWER" =~ "shower" ]]; then
        W_ICON="" # Rain / Drizzle (Using working water drop icon)
    elif [[ "$DESC_LOWER" =~ "snow" || "$DESC_LOWER" =~ "sleet" || "$DESC_LOWER" =~ "flurries" ]]; then
        W_ICON="" # Snow
    elif [[ "$DESC_LOWER" =~ "thunder" || "$DESC_LOWER" =~ "storm" ]]; then
        W_ICON="" # Lightning
    elif [[ "$DESC_LOWER" =~ "cloud" || "$DESC_LOWER" =~ "overcast" ]]; then
        W_ICON="" # Clouds
    elif [[ "$DESC_LOWER" =~ "fog" || "$DESC_LOWER" =~ "mist" || "$DESC_LOWER" =~ "haze" ]]; then
        W_ICON="" # Fog / Mist (Using working cloud icon)
    else
        W_ICON="" # Default weather icon
    fi
    
    # Just format with the icon and the temperature directly, omitting the text description
    WEATHER="$W_ICON  $WEATHER_TEMP"
fi

# Get current time/date in English
DATE_STR=$(LC_TIME="en_US.utf8" date "+%A, %e %B")
TIME_STR=$(date "+%H:%M")

# Form and send notification (-r 9991 prevents duplicates, -t 10000 dismisses in 10s)
notify-send -r 9991 -t 10000 -u normal \
    "  $TIME_STR  —  $DATE_STR" \
    "  St. Petersburg\n$WEATHER"
