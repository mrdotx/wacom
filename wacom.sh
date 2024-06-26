#!/bin/sh

# path:   /home/klassiker/.local/share/repos/wacom/wacom.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/wacom
# date:   2024-07-01T19:57:59+0200

# speed up script by using standard c
LC_ALL=C
LANG=C

get_id() {
    printf "%s" "$list" \
        | awk -v device="$1" '$0 ~ device {print $8}'
}

get_display() {
    displays=$( \
        xrandr \
            | grep "connected" \
    )

    primary=$( \
        printf "%s" "$displays" \
            | grep "primary" \
            | cut -d " " -f1
    )

    secondary=$( \
        printf "%s" "$displays" \
            | grep -v "primary" \
            | head -n1 \
            | cut -d " " -f1
    )

    [ -z "$primary" ] \
        && printf "%s\n" "$secondary" \
        || printf "%s\n" "$primary"
}

get_dimension() {
    resolution=$( \
        xrandr \
            | grep "^$1" \
            | grep -oE '[0-9]{1,4}x[0-9]{1,4}'
    )

    x="${resolution%%x*}"
    y="${resolution##*x}"

    wacom_x=$( \
        xsetwacom get "$2" Area \
            | cut -d " " -f3
    )

    # reducing the drawing area height 15200 * 1080 / 1920 = 8550
    # default 0 0 15200 9500
    printf "0 0 %d %d\n" "$wacom_x" "$((wacom_x * y / x))"
}

set_wacom() {
    id=$(get_id "$1")
    display=${2:-"$(get_display)"}
    dimension=$(get_dimension "$display" "$id")

    printf "xsetwacom set %s [%s] MapToOutput [%s]\n" \
        "$id" "$1" "$display"
    xsetwacom set "$id" MapToOutput "$display"
    printf "xsetwacom set %s [%s] Area [%s -> %s]\n" \
        "$id" "$1" "$(xsetwacom get "$id" Area)" "$dimension"
    xsetwacom set "$id" Area "$dimension"
}

# wait x times/seconds for the connection
count=10
while [ $count -ge 1 ]; do
    list=$(xsetwacom list devices)
    [ -n "$list" ] \
        && break
    sleep 1
    count=$((count - 1))
done

if [ -n "$list" ]; then
    set_wacom "stylus" "$1"
    set_wacom "eraser" "$1"
else
    printf "no tablet connected for configuration"
    exit 0
fi
