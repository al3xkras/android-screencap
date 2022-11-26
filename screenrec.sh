intent_name=com.tomerpacific.camera2api
battery_level_min=5
screencap_delay=2
command_delay=1
width=1920
height=1080
temp_folder=/data/tmp
screen_set_tmp=./screen_set.txt

function brightness() {
  mode=$1
  if [ "$mode" = "set" ]; then
      su -c echo 0 > /sys/class/leds/lcd-backlight/brightness &&
        su -c echo 0 > /sys/class/leds/lcd-backlight/max_brightness
  elif [ "$mode" = "reset" ]; then
      su -c echo 255 > /sys/class/leds/lcd-backlight/max_brightness &&
        su -c echo 1 > /sys/class/leds/lcd-backlight/brightness
  fi
}

function can_set() {
    is_set=$(cat ./screen_set.txt) == 1
    echo is set "$is_set"
    if [ "$is_set" ]; then
        echo 1
    fi
    echo 0
}

function screen() {
  mode=$1
  password=$2
  is_set=$(can_set)
  if [ "$mode" = "unlock" ]; then
     input keyevent KEYCODE_WAKEUP &&
      input keyevent 82 &&
      input swipe 600 600 0 0 &&
      input text "$password" &&
      input keyevent 66
     sleep $command_delay
  elif [ "$mode" = "lock" ]; then
     input keyevent 26 &&
     sleep $command_delay
  elif [ "$mode" = "set" ]; then
    if [ "$is_set" -eq 1 ]; then
        cat<'screen setup can not be done'
        return 1
    fi
    echo 1 > $screen_set_tmp
    sleep $command_delay
  elif [ "$mode" = "reset" ]; then
    echo 0 > $screen_set_tmp
    wm size reset && wm density reset
    sleep $command_delay
  fi
}

function start_intent() {
   am start -n com.tomerpacific.camera2api/.MainActivity &&
   sleep $command_delay
}

function stop_intent() {
    am kill $intent_name &&
    sleep $command_delay
}

function capture_frame() {
   input keyevent KEYCODE_FOCUS &&
   input keyevent KEYCODE_CAMERA
}

function get_battery_level() {
    battery_level=$(dumpsys battery | grep level | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')
    echo "$battery_level"
}

if [ $# = 0 ]; then
    echo 'please specify action: start|stop'
    return 1
fi
loop_limit=-1
if [ $# -gt 1 ]; then
  loop_limit=$2
fi

mode=$1

if [ "$mode" = "start" ]; then
    screen reset && screen unlock ppp333cc1 && screen set
    battery_level=$(get_battery_level)
    echo battery level:"$battery_level"

    initial_delay=5
    post_init_delay=3
    sleep $initial_delay
    start_intent
    sleep $post_init_delay

    loop_number=0
    while [ "$battery_level" -gt "$battery_level_min" ] && [ "$loop_limit" -lt 0 ] || [ "$loop_number" -lt "$loop_limit" ]; do
        loop_number=$((loop_number+1));
        battery_level=$(get_battery_level)
        capture_frame
        echo battery level $battery_level
        echo 'loop div '$((loop_number%5))
        if [ "$((loop_number%5))" -eq 0 ]; then
          start_intent
        fi
        sleep $screencap_delay
    done
    sleep $post_init_delay
    screen reset &&
          screen lock &&
          brightness reset
    return 0
elif [ "$mode" = "stop" ]; then
    screen reset &&
      screen lock &&
      brightness reset
    return 0
fi