#!/bin/sh
sleep 3
pkill hyprsunset
sleep 0.5
hyprsunset -i &
sleep 1
hyprctl hyprsunset gamma 60
