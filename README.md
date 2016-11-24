
Make a video out of a text versioned with git. Based on [git-playback](https://github.com/mmozuras/git-playback)

# How-To

- cd PATH_TO_REPO
- textreplay.sh file
- ... the program redo the history of selected file in the current branch. The output folder is created insiderepo. (NB: the git repo will be headless in a previous state upon crash)
- `makepng.sh hash.csv` 
    - NB: needs a X server running, if launched through ssh use `DISPLAY=:0 makepng.sh hash.csv`
- `makemp4_big.sh` to create a 4k animation at 30FPS
- "process" the output of "history.csv" through the ods calc in `process`
- `run_weather.pd` to output the audio track (set 30 FPS, click read, rewind, start recording and metronome, upon completion manually untoggle the start box and then click stop).
- process audio track as wished (e.g. audacity and low-pass + reverb + normalize)
- merge audio and video using e.g. `ffmpeg -i video.mp4 -i audio.mp3 -codec copy -shortest output.mp3`

# Dependencies

- cutycapt
- ffmpeg3
- pure data
- LibreOffice (!)

Tested on kubuntu 16.04

# Misc

For cutycapt to work well with font, install them on the system. E.g. copy ttf files in "/usr/share/fonts/truetype/custom/" and run `sudo fc-cache -fv`.
