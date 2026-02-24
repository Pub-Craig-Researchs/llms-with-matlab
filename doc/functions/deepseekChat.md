# `deepseekChat`

Connect to DeepSeek Chat APIs from MATLAB.

# Description

`CHAT = deepseekChat(systemPrompt)` creates a `deepseekChat` object with the specified system prompt.

`CHAT = deepseekChat(systemPrompt, Name=Value)` specifies additional options using one or more name-value arguments.

# Input Arguments

- `systemPrompt` — Text that sets the behavior of the assistant. It can also be empty `""`.

# Name-Value Arguments

- `APIKey` — An API key to connect to the DeepSeek API. By default, the `deepseekChat` object looks for an API key stored in the environment variable `DEEPSEEK_API_KEY`.
- `ModelName` — The name of the model to use for chat completions. The default value is `"deepseek-chat"`. Valid models are `"deepseek-chat"` and `"deepseek-reasoner"`.
- `Temperature` — Temperature value for controlling the randomness of the output. The default value is `1`.
- `TopP` — Top probability mass value for controlling the diversity of the output. The default value is `1`.
- `Tools` — Array of `openAIFunction` objects representing custom tools to be used during chat completions.
- `StopSequences` — Vector of strings that when encountered, will cease the generation of tokens.
- `PresencePenalty` — Penalty value for using a token in the response that has already been used. The default value is `0`.
- `FrequencyPenalty` — Penalty value for using a token that is frequent in the training data. The default value is `0`.
- `TimeOut` — Connection Timeout in seconds. The default value is `10`.
- `StreamFun` — Function to callback when streaming the result.
- `ResponseFormat` — The format of the response the model returns. Supported formats are `"text"` (default), `"json"`, `struct`, or a string with JSON Schema.

# Examples

## Connect to DeepSeek API

```matlab
% Assumes you have set the environment variable DEEPSEEK_API_KEY
chat = deepseekChat("You are a helpful assistant.");
response = generate(chat, "What is the capital of France?");
disp(response)
```

## Stream Response

```matlab
chat = deepseekChat("You are a poetic assistant.");
response = generate(chat, "Write a short poem about MATLAB.", StreamFun=@disp);
```
