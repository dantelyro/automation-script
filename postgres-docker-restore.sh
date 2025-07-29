#!/bin/bash

BACKUP_FOLDER="/mnt/c/tmp"
POSTGRES_VERSION="15"
POSTGRES_USER="myuser"
POSTGRES_PASSWORD="mypassword"

if [ ! -d "$BACKUP_FOLDER" ]; then
  echo "Error: First define a backup folder"
  exit 1
fi

dump_files=("$BACKUP_FOLDER"/*.dump)

if [ ! -e "${dump_files[0]}" ]; then
  echo "No dump files in $BACKUP_FOLDER"
  exit 1
fi

echo "Available dump files:"
echo "===================="
for i in "${!dump_files[@]}"; do
  filename=$(basename "${dump_files[i]}")
  echo "$((i+1)) $filename"
done

echo
read -p "Select file number and press Enter: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#dump_files[@]} ]; then
    echo "Invalid selection"
    exit 1
fi

selected_file="${dump_files[$((choice-1))]}"
filename=$(basename "$selected_file")
db_name="${filename%.dump}"
container_name="$db_name"

echo "path: $selected_file" 
echo "Selected: $filename"
echo "Database: $db_name"
echo "Container: $container_name"
echo

read -p "Press Enter to continue or 'q' to quit: " confirm

if [[ "$confirm" == "q" ]]; then
    echo "Cancelled"
    exit 0
fi

echo "Creating container..."
docker run -d \
  --name "$container_name" \
  -e POSTGRES_DB="$db_name" \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -p 5432:5432 \
  postgres:$POSTGRES_VERSION

# Wait for startup
echo "Waiting for PostgreSQL to start..."
sleep 10

docker cp "$selected_file" "$container_name":/tmp/"$filename"
docker exec -i "$container_name" pg_restore -U "$POSTGRES_USER" -d "$db_name" -v /tmp/"$filename"

echo
echo "✅ Restore completed successfully!"
echo
echo "Connection Details:"
echo "=================="
echo "Host: localhost"
echo "Port: $POSTGRES_PORT"
echo "Database: $db_name"
echo "Username: $POSTGRES_USER"
echo "Password: $POSTGRES_PASSWORD"
echo
echo "Connection String:"
echo "postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$db_name"
echo
echo "Docker Commands:"
echo "================"
echo "Connect via psql: docker exec -it $container_name psql -U $POSTGRES_USER -d $db_name"
echo "Stop container:   docker stop $container_name"
echo "Start container:  docker start $container_name"
echo "Remove container: docker rm $container_name"