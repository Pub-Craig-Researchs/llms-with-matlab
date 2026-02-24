classdef(Sealed) deepseekChat < llms.internal.textGenerator & ...
        llms.internal.gptPenalties & llms.internal.hasTools & llms.internal.needsAPIKey
    %deepseekChat Chat completion API from DeepSeek.
    %
    %   CHAT = deepseekChat(systemPrompt) creates an deepseekChat object with the
    %   specified system prompt.
    %
    %   CHAT = deepseekChat(systemPrompt,APIKey=key) uses the specified API key
    %
    %   CHAT = deepseekChat(systemPrompt,Name=Value) specifies additional options
    %   using one or more name-value arguments:
    %
    %   ModelName               - Name of the model to use for chat completions.
    %                             The default value is "deepseek-chat".
    %
    %   Temperature             - Temperature value for controlling the randomness
    %                             of the output. Default value is 1.
    %
    %   TopP                    - Top probability mass value for controlling the
    %                             diversity of the output. Default value is 1.
    %
    %   Tools                   - Array of openAIFunction objects representing
    %                             custom functions to be used during chat completions.
    %
    %   StopSequences           - Vector of strings that when encountered, will
    %                             stop the generation of tokens. Default
    %                             value is empty.
    %
    %   PresencePenalty         - Penalty value for using a token in the response
    %                             that has already been used. Default value is 0.
    %
    %   FrequencyPenalty        - Penalty value for using a token that is frequent
    %                             in the output. Default value is 0.
    %
    %   TimeOut                 - Connection Timeout in seconds. Default value is 10.
    %
    %   StreamFun               - Function to callback when streaming the
    %                             result
    %
    %   ResponseFormat          - The format of response the model returns.
    %                             "text" (default) | "json" | struct | string with JSON Schema
    %
    %   deepseekChat Functions:
    %       deepseekChat         - Chat completion API from DeepSeek.
    %       generate             - Generate a response using the deepseekChat instance.
    %
    %   deepseekChat Properties:
    %       ModelName            - Model name.
    %
    %       Temperature          - Temperature of generation.
    %
    %       TopP                 - Top probability mass to consider for generation.
    %
    %       StopSequences        - Sequences to stop the generation of tokens.
    %
    %       PresencePenalty      - Penalty for using a token in the
    %                              response that has already been used.
    %
    %       FrequencyPenalty     - Penalty for using a token that is
    %                              frequent in the training data.
    %
    %       SystemPrompt         - System prompt.
    %
    %       FunctionNames        - Names of the functions that the model can
    %                              request calls.
    %
    %       ResponseFormat      - The format of response the model returns.
    %                              "text" | "json" | struct | string with JSON Schema
    %
    %       TimeOut              - Connection Timeout in seconds.

    % Copyright 2024-2025 The MathWorks, Inc.

    properties(SetAccess=private)
        %MODELNAME   Model name.
        ModelName
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = @llms.internal.sendRequestWrapper
    end

    methods
        function this = deepseekChat(systemPrompt, nvp)
            arguments
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.ModelName                (1,1) string {mustBeDeepSeekModel} = "deepseek-chat"
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopP                           {llms.utils.mustBeValidProbability} = 1
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat                 {llms.utils.mustBeResponseFormat} = "text"
                nvp.APIKey                         {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.PresencePenalty                {llms.utils.mustBeValidPenalty} = 0
                nvp.FrequencyPenalty               {llms.utils.mustBeValidPenalty} = 0
                nvp.TimeOut                  (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 10
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
            end

            if isfield(nvp,"StreamFun")
                this.StreamFun = nvp.StreamFun;
            else
                this.StreamFun = [];
            end

            if isempty(nvp.Tools)
                this.Tools = [];
                this.FunctionsStruct = [];
                this.FunctionNames = [];
            else
                this.Tools = nvp.Tools;
                [this.FunctionsStruct, this.FunctionNames] = functionAsStruct(nvp.Tools);
            end

            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if systemPrompt ~= ""
                    this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.ModelName = nvp.ModelName;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.StopSequences = nvp.StopSequences;
            this.ResponseFormat = nvp.ResponseFormat;
            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
            this.APIKey = llms.internal.getApiKeyFromNvpOrEnv(nvp,"DEEPSEEK_API_KEY");
            this.TimeOut = nvp.TimeOut;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the deepseekChat instance.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(CHAT, MESSAGES) generates a response
            %   with the specified MESSAGES.

            arguments
                this                    (1,1) deepseekChat
                messages                      {mustBeValidMsgs}
                nvp.ModelName           (1,1) string {mustBeDeepSeekModel} = this.ModelName
                nvp.Temperature               {llms.utils.mustBeValidTemperature} = this.Temperature
                nvp.TopP                      {llms.utils.mustBeValidProbability} = this.TopP
                nvp.StopSequences             {llms.utils.mustBeValidStop} = this.StopSequences
                nvp.ResponseFormat            {llms.utils.mustBeResponseFormat} = this.ResponseFormat
                nvp.APIKey                    {llms.utils.mustBeNonzeroLengthTextScalar} = this.APIKey
                nvp.PresencePenalty           {llms.utils.mustBeValidPenalty} = this.PresencePenalty
                nvp.FrequencyPenalty          {llms.utils.mustBeValidPenalty} = this.FrequencyPenalty
                nvp.TimeOut             (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFun           (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
                nvp.NumCompletions      (1,1) {mustBeNumeric,mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBeNumeric,mustBePositive} = inf
                nvp.ToolChoice          (1,:) {mustBeTextScalar} = "auto"
                nvp.Tools               (1,:) {mustBeA(nvp.Tools, "openAIFunction")}
                nvp.Seed                      {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            if ~isfield(nvp, 'Tools')
                functionsStruct = this.FunctionsStruct;
                functionNames = this.FunctionNames;
            else
                [functionsStruct, functionNames] = functionAsStruct(nvp.Tools);
            end

            mustBeValidFunctionCall(this, nvp.ToolChoice, functionNames);
            toolChoice = convertToolChoice(this, nvp.ToolChoice, functionNames);

            messages = convertCharsToStrings(messages);
            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = this.encodeImages(messages.Messages);
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end

            if isfield(nvp,"StreamFun")
                streamFun = nvp.StreamFun;
            else
                streamFun = this.StreamFun;
            end

            try % just for nicer errors, reducing the stack depth shown
                [text, message, response] = llms.internal.callOpenAIChatAPI(messagesStruct, functionsStruct,...
                    ModelName=nvp.ModelName, ToolChoice=toolChoice, Temperature=nvp.Temperature, ...
                    TopP=nvp.TopP, NumCompletions=nvp.NumCompletions,...
                    StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    PresencePenalty=nvp.PresencePenalty, FrequencyPenalty=nvp.FrequencyPenalty, ...
                    ResponseFormat=nvp.ResponseFormat,Seed=nvp.Seed, ...
                    APIKey=nvp.APIKey,TimeOut=nvp.TimeOut, StreamFun=streamFun, ...
                    Endpoint="https://api.deepseek.com/chat/completions", ...
                    sendRequestFcn=this.sendRequestFcn);
            catch e
                throw(e);
            end

            if isfield(response.Body.Data,"error")
                err = response.Body.Data.error.message;
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err));
            end

            if ~isempty(text)
                text = llms.internal.reformatOutput(text,nvp.ResponseFormat);
            end
        end
    end

    methods(Hidden)
        function messageStruct = encodeImages(~, messageStruct)
            for k=1:numel(messageStruct)
                if isfield(messageStruct{k},"images")
                    images = messageStruct{k}.images;
                    detail = messageStruct{k}.image_detail;
                    messageStruct{k} = rmfield(messageStruct{k},["images","image_detail"]);
                    messageStruct{k}.content = ...
                        {struct("type","text","text",messageStruct{k}.content)};
                    for img = images(:).'
                        if startsWith(img,("https://"|"http://"))
                            s = struct( ...
                                "type","image_url", ...
                                "image_url",struct("url",img));
                        else
                            [~,~,ext] = fileparts(img);
                            MIMEType = "data:image/" + erase(ext,".") + ";base64,";
                            % Base64 encode the image using the given MIME type
                            fid = fopen(img);
                            im = fread(fid,'*uint8');
                            fclose(fid);
                            b64 = matlab.net.base64encode(im);
                            s = struct( ...
                                "type","image_url", ...
                                "image_url",struct("url",MIMEType + b64));
                        end

                        s.image_url.detail = detail;

                        messageStruct{k}.content{end+1} = s;
                    end
                end
            end
        end
    end
end

function [functionsStruct, functionNames] = functionAsStruct(functions)
numFunctions = numel(functions);
functionsStruct = cell(1, numFunctions);
functionNames = strings(1, numFunctions);

for i = 1:numFunctions
    functionsStruct{i} = struct('type','function', ...
        'function',encodeStruct(functions(i)));
    functionNames(i) = functions(i).FunctionName;
end
end

function mustBeValidMsgs(value)
if isa(value, "messageHistory")
    if numel(value.Messages) == 0
        error("llms:mustHaveMessages", llms.utils.errorMessageCatalog.getMessage("llms:mustHaveMessages"));
    end
else
    try
        llms.utils.mustBeNonzeroLengthTextScalar(value);
    catch ME
        error("llms:mustBeMessagesOrTxt", llms.utils.errorMessageCatalog.getMessage("llms:mustBeMessagesOrTxt"));
    end
end
end

function mustBeIntegerOrEmpty(value)
if ~isempty(value)
    mustBeNumeric(value)
    mustBeInteger(value)
end
end

function mustBeDeepSeekModel(model)
mustBeMember(model, ["deepseek-chat", "deepseek-reasoner"]);
end
