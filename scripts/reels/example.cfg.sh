# Example reel: 4 voiced beats. Pexels clip ids are public; download each to raw/<id>.mp4 first.
# Steps: ../voice/tts.py example_lines.txt work/voice_example → set LEN from the printed durations
#        (duration + ~0.35s), render_cards.py example_cards.html work/cards_example, then
#        MUSIC=work/music.mp3 ./build_reel.sh example.cfg.sh
NAME=example
CLIP=(x 6153727 33315143 33688494 35424378)
LEN=( x 3.2     3.6      3.4      2.9)
DIR=( x l2r     u2d      d2u      l2r)
SEEK=(x 0.5     1.0      1.0      20.0)
VOICE_DIR=work/voice_example
VOICE_LEAD=0.12
MUSIC_VOL=0.07
VOICE_VOL=2.8
MUSIC_START=0
CAPTIONS=1
