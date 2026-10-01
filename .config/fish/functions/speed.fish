function speed --description "Independent CLI network speed benchmark"
    # Parse CLI arguments
    set -l sizes
    set -l force_mode ""
    for arg in $argv
        switch $arg
            case -h --help
                echo "Usage: speed [options] [sizes in MB...] (default: 25)"
                echo ""
                echo "Options:"
                echo "  -r, --ru    Use Russian targets (Selectel / FDCservers DME)"
                echo "  -e, --eu    Use European targets (Hetzner / Tele2)"
                echo "  -h, --help  Show this help message"
                echo ""
                echo "Examples:"
                echo "  speed         # Run default 25 MB benchmark (auto-detect location)"
                echo "  speed 10      # Run quick 10 MB test"
                echo "  speed 50      # Run 50 MB test"
                echo "  speed --ru    # Force Russian endpoints"
                return 0
            case -r --ru
                set force_mode "ru"
            case -e --eu
                set force_mode "eu"
            case '*'
                if string match -qr '^[0-9]+$' -- $arg
                    set -a sizes $arg
                else
                    echo (set_color red)"Error: Invalid argument '$arg'. Expected an option or positive integer in MB."(set_color normal)
                    return 1
                end
        end
    end

    if test (count $sizes) -eq 0
        set sizes 25
    end

    # Theme & Colors
    set -l c_reset (set_color normal)
    set -l c_dim (set_color brblack)
    set -l c_cyan (set_color -o cyan)
    set -l c_green (set_color -o green)
    set -l c_blue (set_color -o blue)
    set -l c_yellow (set_color -o yellow)
    set -l c_red (set_color -o red)
    set -l c_title (set_color -o white)

    # Spinner animation frames
    set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    set -l frame_count (count $frames)

    # Global tracking variables for cleanup
    set -g __speed_pid ""
    set -g __speed_tmp ""
    set -g __speed_interrupted 0

    function __speed_on_int --on-signal INT
        set -g __speed_interrupted 1
        printf "\e[?25h\n"
        if test -n "$__speed_pid"
            kill -TERM $__speed_pid 2>/dev/null
        end
        if test -n "$__speed_tmp" -a -f "$__speed_tmp"
            rm -f $__speed_tmp
        end
        echo (set_color red)"Benchmark aborted."(set_color normal)
        return 130
    end

    printf "\e[?25l" # Hide cursor

    # Initial Banner
    echo ""
    echo " $c_title󰛳  Network Benchmark$c_reset $c_dim(Independent / No BigTech)$c_reset"
    echo " $c_dim─────────────────────────────────────────────────────────$c_reset"

    # --- RESOLVE SOURCE LOCATION ---
    set -g __speed_tmp (mktemp)
    set -l fetch_cmd '
        res=$(curl -4 -s --connect-timeout 2 --max-time 3 ipinfo.io 2>/dev/null)
        if [ -z "$res" ] || ! echo "$res" | grep -q "country"; then
            res=$(curl -4 -s --connect-timeout 2 --max-time 3 "https://ipwho.is/" 2>/dev/null)
        fi
        echo "$res"
    '
    sh -c "$fetch_cmd" > $__speed_tmp 2>/dev/null &
    set -g __speed_pid $last_pid

    set -l f_idx 1
    while kill -0 $__speed_pid 2>/dev/null
        if test $__speed_interrupted -eq 1
            break
        end
        printf "\r\e[2K  %s%s%s Resolving source location..." $c_yellow $frames[$f_idx] $c_reset
        set f_idx (math "$f_idx % $frame_count + 1")
        sleep 0.08
    end
    wait $__speed_pid 2>/dev/null

    set -l raw_info (cat $__speed_tmp 2>/dev/null)
    rm -f $__speed_tmp

    set -l src_str "Unknown"
    set -l detected_country ""
    if test -n "$raw_info"
        set -l city ""
        set -l country ""
        set -l org ""
        set -l ip ""

        if type -q jq
            set city (echo $raw_info | jq -r ".city // empty" 2>/dev/null)
            set country (echo $raw_info | jq -r ".country_code // .country // empty" 2>/dev/null)
            set org (echo $raw_info | jq -r ".org // .connection.isp // empty" 2>/dev/null | string replace -r "^AS[0-9]+ " "")
            set ip (echo $raw_info | jq -r ".ip // empty" 2>/dev/null)
        else
            set city (echo $raw_info | string match -r '"city":\s*"([^"]+)"' | tail -n1)
            set country (echo $raw_info | string match -r '"(country_code|country)":\s*"([^"]+)"' | tail -n1)
            set org (echo $raw_info | string match -r '"(org|isp)":\s*"([^"]+)"' | tail -n1 | string replace -r "^AS[0-9]+ " "")
            set ip (echo $raw_info | string match -r '"ip":\s*"([^"]+)"' | tail -n1)
        end
        set detected_country $country

        set -l parts
        if test -n "$city" -a -n "$country"
            set -a parts "$city, $country"
        else if test -n "$country"
            set -a parts "$country"
        end

        if test -n "$org"
            set -a parts "$org"
        end

        if test (count $parts) -gt 0
            set src_str (string join " • " $parts)
            if test -n "$ip"
                set src_str "$src_str ($ip)"
            end
        else if test -n "$ip"
            set src_str "$ip"
        end
    end

    # Determine benchmark targets (RU vs EU/International)
    set -l target_mode $force_mode
    if test -z "$target_mode"
        if test "$detected_country" = "RU" -o "$detected_country" = "Russia"
            set target_mode "ru"
        else
            set target_mode "eu"
        end
    end

    set -l target_desc ""
    set -l dl_url_100 ""
    set -l dl_url_1g ""
    set -l up_url ""
    set -l dl_fallback_100 ""
    set -l dl_fallback_1g ""
    set -l up_fallback ""

    if test "$target_mode" = "ru"
        set target_desc "Selectel (Russia, Down) • FDCservers (Moscow, Up)"
        set dl_url_100 "https://speedtest.selectel.ru/100MB"
        set dl_url_1g "https://speedtest.selectel.ru/1GB"
        set dl_fallback_100 "https://mirror.yandex.ru/archlinux/iso/latest/archlinux-x86_64.iso"
        set dl_fallback_1g "https://mirror.yandex.ru/archlinux/iso/latest/archlinux-x86_64.iso"
        set up_url "http://speedtest.dme.fdcservers.net:8080/speedtest/upload.php"
        set up_fallback "http://speedtest.procloud.ru:8080/speedtest/upload.php"
    else
        set target_desc "Hetzner (Helsinki, Down) • Tele2 (Europe, Up)"
        set dl_url_100 "https://hel1-speed.hetzner.com/100MB.bin"
        set dl_url_1g "https://hel1-speed.hetzner.com/1GB.bin"
        set dl_fallback_100 "https://speedtest.selectel.ru/100MB"
        set dl_fallback_1g "https://speedtest.selectel.ru/1GB"
        set up_url "http://speedtest.tele2.net/upload.php"
        set up_fallback "http://speedtest.dme.fdcservers.net:8080/speedtest/upload.php"
    end

    printf "\r\e[2K  %sSource%s : %s\n" $c_cyan $c_reset $src_str
    echo "  $c_blue"Target"$c_reset : $target_desc"
    echo " $c_dim─────────────────────────────────────────────────────────$c_reset"
    echo ""

    set -l down_speeds
    set -l up_speeds

    for size_mb in $sizes
        if test $__speed_interrupted -eq 1
            break
        end

        # --- 1. DOWNLOAD TEST ---
        set -l dl_url $dl_url_100
        if test $size_mb -gt 100
            set dl_url $dl_url_1g
        end

        set -l end_byte (math "$size_mb * 1048576 - 1")
        set -g __speed_tmp (mktemp)
        set -l t_start_ns (date +%s%N)

        curl -4 -s -r "0-$end_byte" -o /dev/null -w "%{speed_download}" \
             --connect-timeout 5 --max-time 180 "$dl_url" > $__speed_tmp 2>/dev/null &
        set -g __speed_pid $last_pid

        set -l f_idx 1
        set -l ticks 0
        while kill -0 $__speed_pid 2>/dev/null
            if test $__speed_interrupted -eq 1
                break
            end
            set -l cur_sec (math -s1 "$ticks * 0.08")
            printf "\r\e[2K  %s%s%s  %s↓ Download%s  %3d MB  ... %s[%4.1fs]%s" \
                $c_yellow $frames[$f_idx] $c_reset $c_cyan $c_reset $size_mb $c_dim $cur_sec $c_reset
            set f_idx (math "$f_idx % $frame_count + 1")
            set ticks (math "$ticks + 1")
            sleep 0.08
        end
        wait $__speed_pid 2>/dev/null

        if test $__speed_interrupted -eq 1
            break
        end

        set -l t_end_ns (date +%s%N)
        set -l t_dur (math -s1 "($t_end_ns - $t_start_ns) / 1000000000")
        set -l raw_down (string trim (cat $__speed_tmp 2>/dev/null))
        rm -f $__speed_tmp

        set -l speed_down 0
        if test -n "$raw_down"
            set raw_down (string replace ',' '.' -- $raw_down)
            if string match -qr '^[0-9]+(\.[0-9]+)?$' -- $raw_down
                set speed_down (math "$raw_down * 8 / 1000000")
            end
        end

        # Fallback if primary download failed
        if test (math "ceil($speed_down)") -le 0 -a -n "$dl_fallback_100"
            set -l fb_url $dl_fallback_100
            if test $size_mb -gt 100
                set fb_url $dl_fallback_1g
            end
            set -g __speed_tmp (mktemp)
            set t_start_ns (date +%s%N)

            curl -4 -s -r "0-$end_byte" -o /dev/null -w "%{speed_download}" \
                 --connect-timeout 5 --max-time 180 "$fb_url" > $__speed_tmp 2>/dev/null &
            set -g __speed_pid $last_pid

            set f_idx 1
            set ticks 0
            while kill -0 $__speed_pid 2>/dev/null
                if test $__speed_interrupted -eq 1
                    break
                end
                set -l cur_sec (math -s1 "$ticks * 0.08")
                printf "\r\e[2K  %s%s%s  %s↓ Download%s  %3d MB  (fallback) ... %s[%4.1fs]%s" \
                    $c_yellow $frames[$f_idx] $c_reset $c_cyan $c_reset $size_mb $c_dim $cur_sec $c_reset
                set f_idx (math "$f_idx % $frame_count + 1")
                set ticks (math "$ticks + 1")
                sleep 0.08
            end
            wait $__speed_pid 2>/dev/null

            if test $__speed_interrupted -eq 1
                break
            end

            set t_end_ns (date +%s%N)
            set t_dur (math -s1 "($t_end_ns - $t_start_ns) / 1000000000")
            set raw_down (string trim (cat $__speed_tmp 2>/dev/null))
            rm -f $__speed_tmp

            if test -n "$raw_down"
                set raw_down (string replace ',' '.' -- $raw_down)
                if string match -qr '^[0-9]+(\.[0-9]+)?$' -- $raw_down
                    set speed_down (math "$raw_down * 8 / 1000000")
                end
            end
        end

        if test (math "ceil($speed_down)") -gt 0
            set -a down_speeds $speed_down
            printf "\r\e[2K  %s✔%s  %s↓ Download%s  %3d MB    %s%7.2f Mbps%s  %s(%4.1fs)%s\n" \
                $c_green $c_reset $c_cyan $c_reset $size_mb $c_green $speed_down $c_reset $c_dim $t_dur $c_reset
        else
            printf "\r\e[2K  %s✖%s  %s↓ Download%s  %3d MB    %s Failed    %s  %s(%4.1fs)%s\n" \
                $c_red $c_reset $c_cyan $c_reset $size_mb $c_red $c_reset $c_dim $t_dur $c_reset
        end

        # --- 2. UPLOAD TEST ---
        set -l up_bytes (math "$size_mb * 1048576")
        set -g __speed_tmp (mktemp)
        set -l t_start_ns (date +%s%N)

        head -c "$up_bytes" /dev/zero | \
            curl -4 -s -o /dev/null -w "%{speed_upload}" \
                 --connect-timeout 5 --max-time 180 \
                 -X POST --data-binary @- "$up_url" > $__speed_tmp 2>/dev/null &
        set -g __speed_pid $last_pid

        set f_idx 1
        set ticks 0
        while kill -0 $__speed_pid 2>/dev/null
            if test $__speed_interrupted -eq 1
                break
            end
            set -l cur_sec (math -s1 "$ticks * 0.08")
            printf "\r\e[2K  %s%s%s  %s↑ Upload%s    %3d MB  ... %s[%4.1fs]%s" \
                $c_yellow $frames[$f_idx] $c_reset $c_blue $c_reset $size_mb $c_dim $cur_sec $c_reset
            set f_idx (math "$f_idx % $frame_count + 1")
            set ticks (math "$ticks + 1")
            sleep 0.08
        end
        wait $__speed_pid 2>/dev/null

        if test $__speed_interrupted -eq 1
            break
        end

        set -l t_end_ns (date +%s%N)
        set -l t_dur (math -s1 "($t_end_ns - $t_start_ns) / 1000000000")
        set -l raw_up (string trim (cat $__speed_tmp 2>/dev/null))
        rm -f $__speed_tmp

        set -l speed_up 0
        if test -n "$raw_up"
            set raw_up (string replace ',' '.' -- $raw_up)
            if string match -qr '^[0-9]+(\.[0-9]+)?$' -- $raw_up
                set speed_up (math "$raw_up * 8 / 1000000")
            end
        end

        # Fallback if primary upload failed
        if test (math "ceil($speed_up)") -le 0 -a -n "$up_fallback"
            set -g __speed_tmp (mktemp)
            set t_start_ns (date +%s%N)

            head -c "$up_bytes" /dev/zero | \
                curl -4 -s -o /dev/null -w "%{speed_upload}" \
                     --connect-timeout 5 --max-time 180 \
                     -X POST --data-binary @- "$up_fallback" > $__speed_tmp 2>/dev/null &
            set -g __speed_pid $last_pid

            set f_idx 1
            set ticks 0
            while kill -0 $__speed_pid 2>/dev/null
                if test $__speed_interrupted -eq 1
                    break
                end
                set -l cur_sec (math -s1 "$ticks * 0.08")
                printf "\r\e[2K  %s%s%s  %s↑ Upload%s    %3d MB  (fallback) ... %s[%4.1fs]%s" \
                    $c_yellow $frames[$f_idx] $c_reset $c_blue $c_reset $size_mb $c_dim $cur_sec $c_reset
                set f_idx (math "$f_idx % $frame_count + 1")
                set ticks (math "$ticks + 1")
                sleep 0.08
            end
            wait $__speed_pid 2>/dev/null

            if test $__speed_interrupted -eq 1
                break
            end

            set t_end_ns (date +%s%N)
            set t_dur (math -s1 "($t_end_ns - $t_start_ns) / 1000000000")
            set raw_up (string trim (cat $__speed_tmp 2>/dev/null))
            rm -f $__speed_tmp

            if test -n "$raw_up"
                set raw_up (string replace ',' '.' -- $raw_up)
                if string match -qr '^[0-9]+(\.[0-9]+)?$' -- $raw_up
                    set speed_up (math "$raw_up * 8 / 1000000")
                end
            end
        end

        if test (math "ceil($speed_up)") -gt 0
            set -a up_speeds $speed_up
            printf "\r\e[2K  %s✔%s  %s↑ Upload%s    %3d MB    %s%7.2f Mbps%s  %s(%4.1fs)%s\n" \
                $c_blue $c_reset $c_blue $c_reset $size_mb $c_blue $speed_up $c_reset $c_dim $t_dur $c_reset
        else
            printf "\r\e[2K  %s✖%s  %s↑ Upload%s    %3d MB    %s Failed    %s  %s(%4.1fs)%s\n" \
                $c_red $c_reset $c_blue $c_reset $size_mb $c_red $c_reset $c_dim $t_dur $c_reset
        end

        # Spacing between stages if multiple tests
        if test (count $sizes) -gt 1
            echo ""
        end
    end

    printf "\e[?25h" # Restore cursor
    functions -e __speed_on_int 2>/dev/null
    set -e __speed_pid
    set -e __speed_tmp
    set -e __speed_interrupted

    # --- SUMMARY IF MULTIPLE TESTS ---
    if test (count $sizes) -gt 1
        echo " "$c_dim"─────────────────────────────────────────────────────────"$c_reset
        
        if test (count $down_speeds) -gt 0
            set -l tot_down 0
            for s in $down_speeds
                set tot_down (math "$tot_down + $s")
            end
            set -l avg_down (math "$tot_down / (count $down_speeds)")
            printf "  %s󰄬%s  Average Download : %s%7.2f Mbps%s\n" $c_green $c_reset $c_green $avg_down $c_reset
        end

        if test (count $up_speeds) -gt 0
            set -l tot_up 0
            for s in $up_speeds
                set tot_up (math "$tot_up + $s")
            end
            set -l avg_up (math "$tot_up / (count $up_speeds)")
            printf "  %s󰄬%s  Average Upload   : %s%7.2f Mbps%s\n" $c_blue $c_reset $c_blue $avg_up $c_reset
        end

        echo ""
    else
        echo ""
    end
end
