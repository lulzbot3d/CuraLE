#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set up Qt-related ENV variables
if [ -e /opt/qt58/bin/qt58-env.sh ]; then
  source /opt/qt58/bin/qt58-env.sh
elif [ -e /opt/qt56/bin/qt56-env.sh ]; then
  source /opt/qt56/bin/qt56-env.sh
fi

# Set up custom python3 site packages related to cura-lulzbot
export PYTHONPATH=/opt/cura-lulzbot/python3.5/site-packages

# Protobuf Custom location
if [ -z "$CURA_LULZBOT_LIBS" ]; then
  CURA_LULZBOT_LIBS="/opt/cura-lulzbot/lib"
fi
if [ ! -z "$CURA_LULZBOT_LIBS" ]; then
  export LD_LIBRARY_PATH="$CURA_LULZBOT_LIBS:$LD_LIBRARY_PATH"
fi
# run cura-lulzbot

$DIR/cura_app.py
