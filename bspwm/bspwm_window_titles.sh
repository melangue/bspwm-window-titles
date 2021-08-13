#!/usr/bin/env bash

# globals
version="1.1"
cache_path="${HOME}/.cache"
icon_map_path="$( dirname "$( readlink -f "$0" )" )/bspwm_window_titles_icon_map.txt"

# defaults
polybar_mode="false"
monocle_mode="false"
format_focused="[ {NAME} ]"
format_normal="{NAME}"

# wraps a text with polybar format command action
# $1 action
# $2 text
polybar_action_cmd() {
  echo "%{A1:${1}:}${2}%{A}"
}

# formats window name with given format
# $1 format
# $2 window name
polybar_format_window_name() {
    echo "$1" | sed "s/{NAME}/$2/"
}

help() {
   echo "bspwm window titles"
   echo "allows you to have bspwm window titles from each monitor in your bar"
   echo "-------------------"
   echo
   echo "Syntax: bspwm_window_titles [-i <FILE_PATH>|m|p|f <FORMAT_FOCUSED|NORMAL>|V]"
   echo "options:"
   echo "h                          Print this help."
   echo "i <FILE_PATH>              Icon map path - custom path to file containing icon map"
   echo "m                          Monocle mode - won't print window names when there is only one window on desktop."
   echo "p                          Polybar action mode - will output window names wrapped with polybar action handlers."
   echo "                           This allows you to directly click on a window name to focus it's window"
   echo "f <FORMAT_FOCUSED|NORMAL>  Format how focused/normal window names are displayed"
   echo "                           You need to supply both polybar format tags (so need to use -f two times)"
   echo "                           Example"
   echo "                           bspwm_window_titles -f \"%{F#f00}{NAME}%{F-}\" -f \"{NAME}\""
   echo "                           focused window name font color red and normal window as is"
   echo "V                          Print software version and exit."
   echo
}

while getopts ":hvmpf:i:" option; do
   case $option in
      h)
         help
         exit;;
      m)
        monocle_mode="true";;
      i)
        icon_map_path="$OPTARG";;
      p)
        polybar_mode="true";;
      f)
        formats+=("$OPTARG");
        [[ -n ${formats[0]} ]] && format_focused="${formats[0]}"
        [[ -n ${formats[1]} ]] && format_normal="${formats[1]}";;
      v)
        echo "Version $version";
        exit;;
      *)
        echo "Error: Invalid option"
        exit;;
   esac
done

icon_map=$( cat "${icon_map_path}" )

# subscribe to events on which the window title list will get updated
bspc subscribe node_focus node_remove desktop_focus | while read -r _; do

    # get all monitors
    monitors=$( bspc query -M )

    for monitor in $monitors; do
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
            # get window name
            window_name=$( echo "$window" | cut -d " " -f 5- )
            # longer window titles if there is only one window
            [[ "$number_of_windows" == "1" ]] && char_cut="40" || char_cut="20"
            # cut the window name
            window_name_short=$( echo "$window_name" | cut -c1-"$char_cut" )

            # get window class and match after a dot to get app name
            window_class=$( echo "$window" | cut -d " " -f 3 | sed 's/.*\.//')

            # if window id matched with list == not empty
            if [[ -n "$window_name" ]]; then
                # trim window name
                window_name=$( echo "$window_name_short" | sed -e 's/^[[:space:]]*//' )

                # display instance name if there is no window title
                if [[ "$window_name" == "N/A" ]]; then
                    window_name=$(echo "$window" | cut -d " " -f 3 | cut -d "." -f 2 )
                fi

                # get icon for class name
                window_icon=$( grep "$window_class" <<< "$icon_map" | cut -d " " -f2 )

                # fallback icon if class not found
                if [[ -z "$window_icon" ]]; then
                    window_icon=$( grep "Fallback" <<< "$icon_map" | cut -d " " -f2 )
                fi

                # join icon and name
                window_name_with_icon="${window_icon} ${window_name}"

                # apply formatting
                if [[ $( bspc query -N -n focused) == "$window_id" ]]; then
                    formatted_window_name=$( polybar_format_window_name "$format_focused" "$window_name_with_icon" )
                else
                    formatted_window_name=$( polybar_format_window_name "$format_normal" "$window_name_with_icon" )
                fi

                # wrap with polybar action cmd
                [[ "$polybar_mode" == "true" ]] && formatted_window_name=$( polybar_action_cmd "bspc node -f ${window_id}" "$formatted_window_name")

                curr_wins+="${formatted_window_name}      "
            fi
        done

        # if monocle set to true then don't print names if there is only one
        if [[ "$monocle_mode" == "true" && "$number_of_windows" == "1" ]]; then
            windows_print=""
        else
            windows_print="$curr_wins"
        fi

        # print out the window names to files for use in a bar
        echo "$windows_print" > "${cache_path}/bspwm_windows_${index}.txt"
        unset curr_wins
    done

    unset index

done
