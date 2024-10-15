#!/bin/bash

# Set the keyboard layout and variant
setxkbmap -layout us -variant altgr-intl -option lv3:ralt_switch

# Apply custom key mappings (like umlauts on the 3rd level)
if [ -f ~/.Xmodmap ]; then
  xmodmap ~/.Xmodmap
fi

# Optionally add the command to ~/.bashrc to make it persistent
if ! grep -Fxq "setxkbmap -layout us -variant altgr-intl -option lv3:ralt_switch" ~/.bashrc; then
  echo "setxkbmap -layout us -variant altgr-intl -option lv3:ralt_switch" >> ~/.bashrc
fi

if ! grep -Fxq "xmodmap ~/.Xmodmap" ~/.bashrc; then
  echo "xmodmap ~/.Xmodmap" >> ~/.bashrc
fi

