#!/bin/sh

# Saltar si el módulo ya está cargado
if lsmod | grep -q "^v4l2loopback"; then
    echo "v4l2loopback ya cargado, omitiendo."
else
    sudo modprobe v4l2loopback exclusive_caps=1 video_nr=10 card_label="AndroidCam"
fi

# Ejecutar exactamente el comando original
ffmpeg -f lavfi -i testsrc=size=1920x1080:rate=30 -vf format=yuv420p -f v4l2 /dev/video10 &
PID=$!

sleep 20

kill "$PID"
wait "$PID" 2>/dev/null