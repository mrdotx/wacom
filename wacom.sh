#!/bin/sh

# path:   /home/klassiker/.local/share/repos/wacom/wacom.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/wacom
# date:   2021-09-20T09:38:31+0200

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

    if [ -z "$primary" ]; then
        printf "%s\n" "$secondary"
    else
        printf "%s\n" "$primary"
    fi
}

get_dimension() {
    resolution=$( \
        xrandr \
        | sed -n "/^$1/,/\+/p" \
            | tail -n 1 \
            | awk '{print $1}' \
    )

    x=$( \
        printf "%s" "$resolution" \
            | sed "s/x.*//"
    )

    y=$( \
        printf "%s" "$resolution" \
            | sed "s/.*x//"
    )

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
    display=$(get_display)
    dimension=$(get_dimension "$display" "$id")

    printf "xsetwacom set %s [%s] MapToOutput %s\n" "$id" "$1" "$display"
    xsetwacom set "$id" MapToOutput "$display"
    printf "xsetwacom set %s [%s] Area %s\n" "$id" "$1" "$dimension"
    xsetwacom set "$id" Area "$dimension"
}

count=10
while [ $count -ge 1 ]; do
    list=$(xsetwacom list devices)
    [ -n "$list" ] \
        && break
    sleep 1
    count=$((count-1))
done

if [ -n "$list" ]; then
    set_wacom "stylus"
    set_wacom "eraser"
else
    printf "no tablet connected for configuration"
    exit 0
fi
