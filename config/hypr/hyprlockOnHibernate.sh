#!/bin/bash

if ! /usr/bin/pidof hyprlock; then
    echo "Locking..."
    /usr/bin/hyprlock --display wayland-1 -q --immediate
fi