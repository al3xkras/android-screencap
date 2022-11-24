function param() {
    name=$1
    width=1920
    height=1080
    temp_folder=/data/tmp
    screen_set_tmp=temp_folder+"/screen_set.txt"
    if [ "$name" == "width" ]; then
      echo $width
    elif [ "$name" == "height" ]; then
      echo $height
    elif [ "$name" == "temp_folder" ]; then
      echo $temp_folder
    elif [ "$name" == "screen_set_tmp" ]; then
      echo $screen_set_tmp
    fi
    return 1
}

function hello() {
    echo 1
}

function brightness() {
  mode=$1
  if [ "$mode" == "set" ]; then
      su -c echo 0 > /sys/class/leds/lcd-backlight/brightness &&
        su -c echo 0 > /sys/class/leds/lcd-backlight/max_brightness
  elif [ "$mode" == "reset" ]; then
      su -c echo 255 > /sys/class/leds/lcd-backlight/max_brightness &&
        su -c echo 1 > /sys/class/leds/lcd-backlight/brightness
  fi
}

function can_set() {
    is_set=$(cat "$(param screen_set_tmp)") == 1
    if [ "$is_set" ]; then
        echo 1
    fi
    echo 0
}

function screen() {

  mode=$1
  password=$2
  is_set=$(can_set)

  if [ "$mode" == "unlock" ]; then
     input keyevent 26 &&
      input keyevent 82 &&
      input swipe "$width"/2 "$width"/2 0 0 &&
      input text "$password" &&
      input keyevent 66
  elif [ "$mode" == "lock" ]; then
     input keyevent 26
  elif [ "$mode" == "set" ]; then
    if [ "$is_set" != 1 ]; then
        cat<'screen setup can not be done'
        return 1
    fi
    echo 1 > $screen_set_tmp
  elif [ "$mode" == "reset" ]; then
    echo 0 > $screen_set_tmp
    wm size reset && wm density reset && brightness reset
  fi
}

function capture_frame() {
   am start -a android.media.action.IMAGE_CAPTURE
   input keyevent KEYCODE_FOCUS && input keyevent KEYCODE_CAMERA
}

function capture() {
    mode=$1
    if [ "$mode" == "start" ]; then
        brightness set &&
          screen reset &&
          screen unlock &&
          screen set &&
          capture_frame
    elif [ "$mode" == "stop" ]; then
        screen reset &&
          screen lock &&
          brightness reset
    fi
}
