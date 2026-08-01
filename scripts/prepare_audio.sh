#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
output_dir="$repo_dir/audio/ambient"
mkdir -p "$output_dir"

normalize() {
  local input=$1
  local output=$2
  local filter=${3:-anull}
  local measured
  measured=$(ffmpeg -hide_banner -nostats -i "$input" -af "$filter,loudnorm=I=-23:TP=-1:LRA=7:print_format=json" -f null /dev/null 2>&1 | sed -n '/^{/,/^}/p')
  local input_i input_tp input_lra input_thresh offset
  input_i=$(jq -r '.input_i' <<<"$measured")
  input_tp=$(jq -r '.input_tp' <<<"$measured")
  input_lra=$(jq -r '.input_lra' <<<"$measured")
  input_thresh=$(jq -r '.input_thresh' <<<"$measured")
  offset=$(jq -r '.target_offset' <<<"$measured")
  ffmpeg -hide_banner -loglevel error -y -i "$input" \
    -af "$filter,loudnorm=I=-23:TP=-1:LRA=7:measured_I=$input_i:measured_TP=$input_tp:measured_LRA=$input_lra:measured_thresh=$input_thresh:offset=$offset:linear=true" \
    -ar 48000 -ac 2 -c:a aac -b:a 192k "$output"
}

# The original 2.25 s Rain and near-silent Forest generations failed QA. The tracked
# 30-second reference recordings are used as clean replacement sources; only normalized,
# uniquely named AAC outputs ship in the app.
normalize "$repo_dir/audio/legacy/rain.mp3" "$output_dir/eira_ambient_rain.m4a"
normalize "$repo_dir/audio/warm_brown_noise_tex_#4-1785503352653.wav" "$output_dir/eira_ambient_drift.m4a"
normalize "$repo_dir/audio/Continuous_gentle_st_#2-1785503641017.wav" "$output_dir/eira_ambient_stream.m4a"
normalize "$repo_dir/audio/Continuous_distant_o_#3-1785502873710.wav" "$output_dir/eira_ambient_ocean.m4a" "atrim=start=0.8:end=6.65,asetpts=PTS-STARTPTS"
normalize "$repo_dir/audio/legacy/forest.mp3" "$output_dir/eira_ambient_forest.m4a"
normalize "$repo_dir/audio/ambient_fireplace,_s_#1-1785503171488.wav" "$output_dir/eira_ambient_hearth.m4a"
normalize "$repo_dir/audio/ambient_summer_night_#4-1785503228390.wav" "$output_dir/eira_ambient_night.m4a"
normalize "$repo_dir/audio/Deep_quiet_cave_ambi_#1-1785503504946.wav" "$output_dir/eira_ambient_cavern.m4a"

for file in "$output_dir"/*.m4a; do
  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$file")
  printf '%s\t%.2fs\n' "$(basename "$file")" "$duration"
done
