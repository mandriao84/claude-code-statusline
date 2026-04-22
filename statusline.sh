#!/bin/bash
IFS= read -rd '' input

dir=""; model=""; sp=""; wp=""; sr=""; wr=""; tp=""; cp=""
[[ "$input" =~ \"project_dir\":\"([^\"]*)\" ]] && dir=${BASH_REMATCH[1]}
[ -z "$dir" ] && [[ "$input" =~ \"current_dir\":\"([^\"]*)\" ]] && dir=${BASH_REMATCH[1]}
[ -z "$dir" ] && [[ "$input" =~ \"cwd\":\"([^\"]*)\" ]] && dir=${BASH_REMATCH[1]}
[[ "$input" =~ \"display_name\":\"([^\"]*)\" ]] && model=${BASH_REMATCH[1]}
[ -z "$model" ] && [[ "$input" =~ \"model\":\{[^}]*\"id\":\"([^\"]*)\" ]] && model=${BASH_REMATCH[1]}
[ -z "$model" ] && model="Claude"
[[ "$input" =~ \"transcript_path\":\"([^\"]*)\" ]] && tp=${BASH_REMATCH[1]}
cw=200000; cwl='200k'
[[ "$model" == *1[mM]* ]] && { cw=1000000; cwl='1M'; }
if [ -n "$tp" ] && [ -f "$tp" ]; then
  last=$(grep -b '"usage"' "$tp" | tail -n 1)
  if [ -n "$last" ]; then
    off=${last%%:*}; line=${last#*:}
    it=0; cr=0; cc=0
    [[ "$line" =~ \"input_tokens\":([0-9]+) ]] && it=${BASH_REMATCH[1]}
    [[ "$line" =~ \"cache_read_input_tokens\":([0-9]+) ]] && cr=${BASH_REMATCH[1]}
    [[ "$line" =~ \"cache_creation_input_tokens\":([0-9]+) ]] && cc=${BASH_REMATCH[1]}
    total=$(wc -c < "$tp"); total=${total// /}
    delta=$(( total - off - ${#line} - 1 ))
    (( delta < 0 )) && delta=0
    cp=$(( (it + cr + cc + delta / 4) * 100 / cw ))
  fi
fi
if [[ "$input" == *'"rate_limits"'* ]]; then
  [[ "$input" =~ \"five_hour\":\{[^}]*\"used_percentage\":([0-9.]+) ]] && sp=${BASH_REMATCH[1]}
  [[ "$input" =~ \"seven_day\":\{[^}]*\"used_percentage\":([0-9.]+) ]] && wp=${BASH_REMATCH[1]}
  [[ "$input" =~ \"five_hour\":\{[^}]*\"resets_at\":([0-9]+) ]] && sr=${BASH_REMATCH[1]}
  [[ "$input" =~ \"seven_day\":\{[^}]*\"resets_at\":([0-9]+) ]] && wr=${BASH_REMATCH[1]}
fi

branch=""
if [ -n "$dir" ] && [ -f "$dir/.git/HEAD" ]; then
  read -r head < "$dir/.git/HEAD"
  case "$head" in
    "ref: refs/heads/"*) branch=${head#ref: refs/heads/} ;;
    "ref: "*) branch=${head#ref: } ;;
    *) branch=${head:0:7} ;;
  esac
fi

effort=""
for f in "$dir/.claude/settings.json" "$HOME/.claude/settings.json"; do
  [ -f "$f" ] || continue
  while IFS= read -r line; do
    if [[ "$line" == *'"effortLevel"'* ]]; then
      [[ "$line" =~ \"effortLevel\":[[:space:]]*\"([^\"]*)\" ]] && effort=${BASH_REMATCH[1]}
      break
    fi
  done < "$f"
  [ -n "$effort" ] && break
done

if [ -n "$sr$wr" ]; then
  printf -v now '%(%s)T' -1 2>/dev/null || now=$EPOCHSECONDS
  if [ -z "$now" ]; then
    c=${TMPDIR:-/tmp}/.sl-now-$UID
    if [ -f "$c" ]; then
      read -r now < "$c"
      (date +%s > "$c.t" && mv "$c.t" "$c") & disown
    else
      now=$(date +%s); echo "$now" > "$c"
    fi
  fi
fi

esc=$'\033'
rst="${esc}[0m"
dim="${esc}[38;2;120;120;120m"
ind="${esc}[38;2;80;80;80m"
sep="   "

grad() {
  local pct=${1%.*}
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  local sR sG sB eR eG eB s t
  if   (( pct <= 15 )); then sR=0   sG=120 sB=255 eR=0   eG=200 eB=0 s=0  t=15
  elif (( pct <= 30 )); then sR=0   sG=200 sB=0   eR=220 eG=220 eB=0 s=15 t=30
  elif (( pct <= 50 )); then sR=220 sG=220 sB=0   eR=255 eG=140 eB=0 s=30 t=50
  elif (( pct <= 70 )); then sR=255 sG=140 sB=0   eR=220 eG=0   eB=0 s=50 t=70
  else                       sR=220 sG=0   sB=0   eR=220 eG=0   eB=0 s=70 t=100
  fi
  local span=$(( t - s )) off=$(( pct - s ))
  printf -v __c '%s[38;2;%d;%d;%dm' "$esc" \
    $(( sR + (eR - sR) * off / span )) \
    $(( sG + (eG - sG) * off / span )) \
    $(( sB + (eB - sB) * off / span ))
}

hum() {
  local delta=$(( ${1%.*} - now ))
  if   (( delta <= 0     )); then __h='0m'
  elif (( delta >= 86400 )); then printf -v __h '%dd' $(( delta / 86400 ))
  elif (( delta >= 3600  )); then printf -v __h '%dh' $(( delta / 3600 ))
  else                            printf -v __h '%dm' $(( delta / 60 ))
  fi
}

cwd="${esc}[2;38;2;160;210;210m~/${dir##*/}$rst"
out=$cwd
[ -n "$branch" ] && { b="${esc}[38;2;160;210;210m@$branch$rst"; [ -n "$out" ] && out+="$sep$b" || out=$b; }
[ -n "$effort" ] && m="${esc}[38;2;204;120;92m$model${esc}[2m/$effort$rst" || m="${esc}[38;2;204;120;92m$model$rst"
[ -n "$out" ] && out+=$sep$m || out=$m

if [ -n "$cp" ]; then
  grad "$cp"
  out+="$sep${__c}s${cp}%$rst${esc}[2m${__c}/$cwl$rst"
fi
if [ -n "$sp" ]; then
  grad "$sp"; printf -v pct '%.0f' "$sp"
  r=""
  [ -n "$sr" ] && { hum "$sr"; r="${esc}[2m$__c>$__h$rst"; }
  out+="$sep${__c}h${pct}%$rst$r"
fi
if [ -n "$wp" ]; then
  grad "$wp"; printf -v pct '%.0f' "$wp"
  r=""
  [ -n "$wr" ] && { hum "$wr"; r="${esc}[2m$__c>$__h$rst"; }
  out+="$sep${__c}w${pct}%$rst$r"
fi

printf '%s\n' "$out"
