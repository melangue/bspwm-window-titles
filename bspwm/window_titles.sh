#!/usr/bin/env bash

bspwm_path="${HOME}/.config/bspwm"

# subscribe to events on which the window title list will get updated
bspc subscribe node_focus node_remove desktop_focus | while read -r _; do

    # get all monitors
    monitors=$( bspc query -M )

    for monitor in $monitors; do

        # index
        index=$((index + 1))

        # get last focused desktop on given monitor
        last_focused_desktop=$( bspc query -D -m "$monitor" -d .active )

        # get windows from last focused desktop on given monitor
        winids_on_desktop=$( bspc query -N -n .window -m "$monitor" -d "$last_focused_desktop" )

        # get number of windows on desktop
        number_of_windows=$( printf "$winids_on_desktop" | tr '\n' ' ' | wc -w  )

        # get a list of all windows
        winlist=$( wmctrl -l -x )

        for window_id in $winids_on_desktop; do
            # replace all spaces and tabs with single spaces for easier cutting
            window=$( echo "$winlist" | grep -i "$window_id" | tr -s '[:blank:]' )
            # get window name and cut it to 20 chars
            window_name=$( echo "$window" | cut -d " " -f 5- | cut -c1-20 )
            # get window class and match after a dot to get app name
            window_class=$( echo "$window" | cut -d " " -f 3 | sed 's/.*\.//')

            # if window id matched with list == not empty
            if [[ -n "$window_name" ]]; then

                # trim window name
                window_name=$( echo "$window_name" | sed -e 's/^[[:space:]]*//' )

                # get icon for class name
                window_icon=$( grep "$window_class" "${bspwm_path}/window_class_icon_map.txt" | cut -d " " -f2 )
                echo "$window_icon"

                # fallback icon if class not found
                if [[ -z "$window_icon" ]]; then
                    window_icon=$( grep "Fallback" "${bspwm_path}/window_class_icon_map.txt" | cut -d " " -f2 )
                fi

                # join icon and name
                window_name_with_icon="${window_icon} ${window_name}"

                # wrap window name in square brackets if it's active
                [[ "$window_id" == $( bspc query -N -n focused) ]] && curr_wins+="[ ${window_name_with_icon} ]   " || curr_wins+="${window_name_with_icon}   "

            fi
        done

        # don't print names if there is only one
        # [[ "$number_of_windows" == "1" ]] && windows_print="" || windows_print="$curr_wins"

        windows_print="$curr_wins"

        # print out the window names to files for use in a bar
        echo "$windows_print" > "${bspwm_path}/current_windows_${index}.txt"
        unset curr_wins

    done

    unset index

done
