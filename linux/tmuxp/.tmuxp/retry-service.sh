#!/bin/bash

# Retry script with exponential backoff for service startup
# Usage: retry-service.sh "command" "service_name" [max_retries] [initial_delay]

COMMAND="$1"
SERVICE_NAME="$2"
MAX_RETRIES="${3:-5}"
INITIAL_DELAY="${4:-5}"

if [ -z "$COMMAND" ] || [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 \"command\" \"service_name\" [max_retries] [initial_delay]"
    echo "Example: $0 \"./fut run amp affiliate\" \"amp-affiliate\" 5 5"
    exit 1
fi

echo "Starting $SERVICE_NAME with retry mechanism..."
echo "Command: $COMMAND"
echo "Max retries: $MAX_RETRIES"
echo "Initial delay: ${INITIAL_DELAY}s"
echo "----------------------------------------"

RETRY_COUNT=0
DELAY=$INITIAL_DELAY

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES for $SERVICE_NAME..."
    
    # Execute the command in the background and capture its PID
    $COMMAND &
    CMD_PID=$!
    
    # Wait for the command to complete or fail
    wait $CMD_PID
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $SERVICE_NAME started successfully!"
        exit 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $SERVICE_NAME failed with exit code $EXIT_CODE"
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ Waiting ${DELAY}s before retry..."
            sleep $DELAY
            DELAY=$((DELAY * 2))  # Exponential backoff: 5s, 10s, 20s, 40s, 80s
        fi
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 💥 $SERVICE_NAME failed after $MAX_RETRIES attempts. Giving up."
exit 1
