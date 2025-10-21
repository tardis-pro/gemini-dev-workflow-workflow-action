#!/bin/bash
set -e

# Multi-Provider AI Orchestrator Script
# Supports: Gemini, Claude, Qwen

PROVIDER="${AI_PROVIDER:-gemini}"
API_KEY="${AI_API_KEY}"
PROMPT_FILE="${AI_PROMPT_FILE}"
OUTPUT_FILE="${AI_OUTPUT_FILE:-ops/out/ai-output.md}"
MODEL="${AI_MODEL:-auto}"

# Check required variables
if [ -z "$API_KEY" ]; then
    echo "Error: AI_API_KEY is required"
    exit 1
fi

if [ -z "$PROMPT_FILE" ] || [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: PROMPT_FILE must exist: $PROMPT_FILE"
    exit 1
fi

# Read prompt file
PROMPT=$(cat "$PROMPT_FILE")

# Function to call Gemini API
call_gemini() {
    local model="${1:-gemini-2.0-flash-exp}"
    echo "Calling Gemini API with model: $model"

    # Create request payload
    local payload=$(jq -n \
        --arg prompt "$PROMPT" \
        '{
            contents: [{
                parts: [{
                    text: $prompt
                }]
            }],
            generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 8192
            }
        }')

    # Call API
    response=$(curl -s -X POST \
        "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Extract text from response
    echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty'
}

# Function to call Claude API
call_claude() {
    local model="${1:-claude-3-5-sonnet-20241022}"
    echo "Calling Claude API with model: $model"

    # Create request payload
    local payload=$(jq -n \
        --arg prompt "$PROMPT" \
        --arg model "$model" \
        '{
            model: $model,
            max_tokens: 8192,
            messages: [{
                role: "user",
                content: $prompt
            }]
        }')

    # Call API
    response=$(curl -s -X POST \
        "https://api.anthropic.com/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: ${API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload")

    # Extract text from response
    echo "$response" | jq -r '.content[0].text // empty'
}

# Function to call Qwen API (Alibaba Cloud DashScope)
call_qwen() {
    local model="${1:-qwen-max}"
    echo "Calling Qwen API with model: $model"

    # Create request payload
    local payload=$(jq -n \
        --arg prompt "$PROMPT" \
        --arg model "$model" \
        '{
            model: $model,
            input: {
                messages: [{
                    role: "user",
                    content: $prompt
                }]
            },
            parameters: {
                result_format: "message"
            }
        }')

    # Call API
    response=$(curl -s -X POST \
        "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_KEY}" \
        -d "$payload")

    # Extract text from response
    echo "$response" | jq -r '.output.choices[0].message.content // empty'
}

# Function to call local Qwen (Ollama)
call_qwen_local() {
    local model="${1:-qwen2.5:latest}"
    echo "Calling local Qwen (Ollama) with model: $model"

    # Create request payload
    local payload=$(jq -n \
        --arg prompt "$PROMPT" \
        --arg model "$model" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false
        }')

    # Call local Ollama API
    response=$(curl -s -X POST \
        "http://localhost:11434/api/generate" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Extract text from response
    echo "$response" | jq -r '.response // empty'
}

# Main execution
echo "==============================================="
echo "AI Provider: $PROVIDER"
echo "Model: $MODEL"
echo "Prompt file: $PROMPT_FILE"
echo "Output file: $OUTPUT_FILE"
echo "==============================================="

# Call appropriate provider
case "$PROVIDER" in
    gemini)
        if [ "$MODEL" = "auto" ]; then
            MODEL="gemini-2.0-flash-exp"
        fi
        result=$(call_gemini "$MODEL")
        ;;
    claude)
        if [ "$MODEL" = "auto" ]; then
            MODEL="claude-3-5-sonnet-20241022"
        fi
        result=$(call_claude "$MODEL")
        ;;
    qwen)
        if [ "$MODEL" = "auto" ]; then
            MODEL="qwen-max"
        fi
        result=$(call_qwen "$MODEL")
        ;;
    qwen-local)
        if [ "$MODEL" = "auto" ]; then
            MODEL="qwen2.5:latest"
        fi
        result=$(call_qwen_local "$MODEL")
        ;;
    *)
        echo "Error: Unsupported provider '$PROVIDER'"
        echo "Supported: gemini, claude, qwen, qwen-local"
        exit 1
        ;;
esac

# Check if we got a result
if [ -z "$result" ]; then
    echo "Error: No response from AI provider"
    exit 1
fi

# Write output
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "$result" > "$OUTPUT_FILE"

echo "✅ Successfully generated output to: $OUTPUT_FILE"
echo "==============================================="
