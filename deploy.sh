#!/bin/bash -xe
# Enable pipefail only if running in bash
[ -n "$BASH_VERSION" ] && set -o pipefail

# --- Variables to edit ---
CHESS_BOT_REPO="https://github.com/MitchelPaulin/Walleye.git"
ENGINE_NAME="walleye"
LICHESS_MIDDLEWARE_REPO="https://github.com/lichess-bot-devs/lichess-bot.git"
TOKEN_PLACEHOLDER="PUT_YOUR_TOKEN_HERE"
APP_DIR="/opt/uci-bot"
MIDDLEWARE_DIR="/opt/lichess-bot"
PYTHON_PATH="/usr/bin/python3"
# ------------------------

# Update system
apt-get update -y
apt-get upgrade -y
apt-get install -y git python3 python3-pip python3-venv curl

# Compiling a rust project in release mode can be too expensive on some of the cheaper AWS instances, 
# Uncomment the lines below to compile from source if able to 

# --- Clone and build Rust UCI engine ---
# apt-get install -y build-essential cmake pkg-config libssl-dev cargo rustc
# mkdir -p $APP_DIR
# git clone --depth=1 "$CHESS_BOT_REPO" $APP_DIR
# cd $APP_DIR
# cargo build --release -j 1

# Compiling a rust project in release mode can be too expensive on some of the cheaper AWS instances, 
# Pull the compiled binary from a github release, note its compiled for ubuntu x86_64, if you have a stronger instance or a different architecture, prefer building from source

mkdir -p $APP_DIR/target/release
curl -L -o $APP_DIR/target/release/walleye https://github.com/MitchelPaulin/Walleye-AWS/raw/refs/heads/main/bin/walleye
curl -L -o $APP_DIR/target/release/book/komodo.bin https://github.com/MitchelPaulin/Walleye-AWS/raw/refs/heads/main/bin/komodo.bin
chmod +x $APP_DIR/target/release/walleye

# --- Clone lichess-bot middleware and set up venv ---
mkdir -p $MIDDLEWARE_DIR
git clone --depth=1 "$LICHESS_MIDDLEWARE_REPO" $MIDDLEWARE_DIR
$PYTHON_PATH -m venv "$MIDDLEWARE_DIR/venv"
$MIDDLEWARE_DIR/venv/bin/python -m pip install --upgrade pip
$MIDDLEWARE_DIR/venv/bin/python -m pip install -r "$MIDDLEWARE_DIR/requirements.txt"

# --- Prepare config with token placeholder ---
cat > $MIDDLEWARE_DIR/config.yml <<EOF
token: "$TOKEN_PLACEHOLDER"
url: "https://lichess.org/"        # Lichess base URL.
engine:
  dir: "$APP_DIR/target/release"
  name: "$ENGINE_NAME"
  working_dir: ""                  # Directory where the chess engine will read and write files. If blank or missing, the current directory is used.
                                   # NOTE: If working_dir is set, the engine will look for files and directories relative to this directory, not where lichess-bot was launched. Absolute paths are unaffected.
  protocol: "uci"                  # "uci", "xboard" or "homemade"
  ponder: false                     # Think on opponent's time.

  polyglot:
    enabled: true                 # Activate polyglot book.
    book:
      standard:                    # List of book file paths for variant standard.
        - "$APP_DIR/target/release/book/komodo.bin"
    min_weight: 1                  # Does not select moves with weight below min_weight (min 0, max: 100 if normalization isn't "none" else 65535).
    selection: "best_move"         # Move selection is one of "weighted_random", "uniform_random" or "best_move" (but not below the min_weight in the 2nd and 3rd case).
    max_depth: 8                   # How many moves from the start to take from the book.
    normalization: "none"          # Normalization method for the book weights. One of "none", "sum", or "max".

  draw_or_resign:
    resign_enabled: false          # Whether or not the bot should resign.
    resign_score: -1000            # If the score is less than or equal to this value, the bot resigns (in cp).
    resign_for_egtb_minus_two: true # If true the bot will resign in positions where the online_egtb returns a wdl of -2.
    resign_moves: 3                # How many moves in a row the score has to be below the resign value.
    offer_draw_enabled: true       # Whether or not the bot should offer/accept draw.
    offer_draw_score: 0            # If the absolute value of the score is less than or equal to this value, the bot offers/accepts draw (in cp).
    offer_draw_for_egtb_zero: true # If true the bot will offer/accept draw in positions where the online_egtb returns a wdl of 0.
    offer_draw_moves: 10           # How many moves in a row the absolute value of the score has to be below the draw value.
    offer_draw_pieces: 10          # Only if the pieces on board are less than or equal to this value, the bot offers/accepts draw.

  online_moves:
    max_out_of_book_moves: 10      # Stop using online opening books after they don't have a move for 'max_out_of_book_moves' positions. Doesn't apply to the online endgame tablebases.
    max_retries: 2                 # The maximum amount of retries when getting an online move.
    # max_depth: 10                # How many moves from the start to take from online books. Default is no limit.
    chessdb_book:
      enabled: false               # Whether or not to use chessdb book.
      min_time: 20                 # Minimum time (in seconds) to use chessdb book.
      max_time: 10800              # Maximum starting game time (in seconds) to use chessdb book.
      move_quality: "good"         # One of "all", "good", "best".
      min_depth: 20                # Only for move_quality: "best".
    lichess_cloud_analysis:
      enabled: false               # Whether or not to use lichess cloud analysis.
      min_time: 20                 # Minimum time (in seconds) the bot must have to use cloud analysis.
      max_time: 10800              # Maximum starting game time (in seconds) the bot must have to use cloud analysis.
      move_quality: "best"         # One of "good", "best".
      max_score_difference: 50     # Only for move_quality: "good". The maximum score difference (in cp) between the best move and the other moves.
      min_depth: 20
      min_knodes: 0
    lichess_opening_explorer:
      enabled: false
      min_time: 20
      max_time: 10800              # Maximum starting game time (in seconds) the bot must have to use the lichess opening explorer.
      source: "masters"            # One of "lichess", "masters", "player"
      player_name: ""              # The lichess username. Leave empty for the bot's username to be used. Used only when source is "player".
      sort: "winrate"              # One of "winrate", "games_played"
      min_games: 10                # Minimum number of times a move must have been played to be chosen.
    online_egtb:
      enabled: false               # Whether or not to enable online endgame tablebases.
      min_time: 20                 # Minimum time (in seconds) the bot must have to use online EGTBs.
      max_time: 10800              # Maximum starting game time (in seconds) the bot must have to use online EGTBs.
      max_pieces: 7                # Maximum number of pieces on the board to use endgame tablebases.
      source: "lichess"            # One of "lichess", "chessdb".
      move_quality: "best"         # One of "best" or "suggest" (it takes all the moves with the same WDL and tells the engine to only consider these; will move instantly if there is only 1 "good" move).

  lichess_bot_tbs:                 # The tablebases list here will be read by lichess-bot, not the engine.
    syzygy:
      enabled: false               # Whether or not to use local syzygy endgame tablebases.
      paths:                       # Paths to Syzygy endgame tablebases.
        - "engines/syzygy"
      max_pieces: 7                # Maximum number of pieces in the endgame tablebase.
      move_quality: "best"         # One of "best" or "suggest" (it takes all the moves with the same WDL and tells the engine to only consider these; will move instantly if there is only 1 "good" move).
    gaviota:
      enabled: false               # Whether or not to use local gaviota endgame tablebases.
      paths:
        - "engines/gaviota"
      max_pieces: 5
      min_dtm_to_consider_as_wdl_1: 120 # The minimum DTM to consider as syzygy WDL=1/-1. Set to 100 to disable.
      move_quality: "best"         # One of "best" or "suggest" (it takes all the moves with the same WDL and tells the engine to only consider these; will move instantly if there is only 1 "good" move).

  homemade_options:
#   Hash: 256

  silence_stderr: false            # Some engines (yes you, Leela) are very noisy.

abort_time: 30                     # Time to abort a game in seconds when there is no activity.
fake_think_time: false             # Artificially slow down the bot to pretend like it's thinking.
rate_limiting_delay: 0             # Time (in ms) to delay after sending a move to prevent "Too Many Requests" errors.
move_overhead: 2000                # Increase if your bot flags games too often.
max_takebacks_accepted: 0          # The number of times to allow an opponent to take back a move in a game.
quit_after_all_games_finish: false # If set to true, then pressing Ctrl-C to quit will only stop lichess-bot after all current games have finished.

correspondence:
  move_time: 60                    # Time in seconds to search in correspondence games.
  checkin_period: 300              # How often to check for opponent moves in correspondence games after disconnecting.
  disconnect_time: 150             # Time before disconnecting from a correspondence game.
  ponder: false                    # Ponder in correspondence games the bot is connected to.

challenge:                         # Incoming challenges.
  concurrency: 1                   # Number of games to play simultaneously.
  sort_by: "best"                  # Possible values: "best" and "first".
  preference: "none"               # Possible values: "none", "human", "bot".
  accept_bot: false                # Accepts challenges coming from other bots.
  only_bot: false                  # Accept challenges by bots only.
  max_increment: 20                # Maximum amount of increment to accept a challenge in seconds. The max is 180. Set to 0 for no increment.
  min_increment: 0                 # Minimum amount of increment to accept a challenge in seconds.
  max_base: 1800                   # Maximum amount of base time to accept a challenge in seconds. The max is 10800 (3 hours).
  min_base: 0                      # Minimum amount of base time to accept a challenge in seconds.
  max_days: 14                     # Maximum number of days per move to accept a challenge for a correspondence game.
                                   # Unlimited games can be accepted by removing this field or specifying .inf
  min_days: 1                      # Minimum number of days per move to accept a challenge for a correspondence game.
  variants:                        # Chess variants to accept (https://lichess.org/variant).
    - standard
  time_controls:                   # Time controls to accept (bots are not allowed to play ultraBullet).
    - bullet
    - blitz
    - rapid
  modes:                           # Game modes to accept.
    - casual                       # Unrated games.
    - rated                        # Rated games - must comment if the engine doesn't try to win.
  bullet_requires_increment: false # Require that bullet game challenges from bots have a non-zero increment
  max_simultaneous_games_per_user: 5  # Maximum number of simultaneous games with the same user

greeting:
    hello: "Hi! I'm {me}." # Message to send to chat at the start of a game
    goodbye: "Good game!" # Message to send to chat at the end of a game

matchmaking:
  allow_matchmaking: false         # Set it to 'true' to challenge other bots.
  allow_during_games: false        # Set it to 'true' to create challenges during long games.
  challenge_variant: "random"      # If set to 'random', the bot will choose one variant from the variants enabled in 'challenge.variants'.
  challenge_timeout: 30            # Create a challenge after being idle for 'challenge_timeout' minutes. The minimum is 1 minute.
  challenge_initial_time:          # Initial time in seconds of the challenge (to be chosen at random).
    - 60
    - 180
  challenge_increment:             # Increment in seconds of the challenge (to be chosen at random).
    - 1
    - 2
#  challenge_days:                 # Days for correspondence challenge (to be chosen at random).
#    - 1
#    - 2
# opponent_min_rating: 600         # Opponents rating should be above this value (600 is the minimum rating in lichess).
# opponent_max_rating: 4000        # Opponents rating should be below this value (4000 is the maximum rating in lichess).
  opponent_rating_difference: 300  # The maximum difference in rating between the bot's rating and opponent's rating.
  rating_preference: "none"        # One of "none", "high", "low".
  challenge_mode: "random"         # Set it to the mode in which challenges are sent. Possible options are 'casual', 'rated' and 'random'.
  challenge_filter: none           # If a bot declines a challenge, do not issue a similar challenge to that bot. Possible options are 'none', 'coarse', and 'fine'.
# block_list:                      # The list of bots that will not be challenged
#   - user1
#   - user2
# online_block_list:               # The urls from which to retrieve a list of bot names that will not be challenged. The list should be a text file where each line contains the name of a blocked bot
#   - example.com/blocklist
  include_challenge_block_list: false  # Do not challenge bots in the challenge: block_list in addition to the matchmaking block list.
EOF

# --- Create systemd service pointing to venv binary ---
cat >/etc/systemd/system/lichess-bot.service <<'UNIT'
[Unit]
Description=Lichess UCI Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/lichess-bot
ExecStart=/opt/lichess-bot/venv/bin/python /opt/lichess-bot/lichess-bot.py -u
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# Reload systemd (do not start yet; wait until token is set)
systemctl daemon-reload
