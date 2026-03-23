/*
 * Copyright 2026 salesforce.com, inc.
 * All Rights Reserved
 * Company Confidential
 */

 public with sharing class ToneChecker {
    
    // System prompt for generating email blocks in CNAVS structure format
    private static final String TONE_CHECKER_SYSTEM_PROMPT = 
        'You are a tone transformation assistant. Your task is to rewrite content in a specified tone while preserving the original meaning, intent, and key details.\n\n' +
        'You will receive the following input parameters:\n' +
        'Text: {text}\n' +
        'TargetTone: {target_tone}\n\n' +
        'Guidelines:\n' +
        '- Do not add or remove important information.\n' +
        '- Change only the tone, vocabulary, and sentence style.\n' +
        '- Keep the output clear, natural, and concise.\n' +
        '- Do not include explanations or extra formatting.\n' +
        '- Return only the rewritten text.\n\n' +
        'Supported tones:\n' +
        '- Energetic\n' +
        '- Professional\n' +
        '- Straight\n\n' +
        'Always rewrite the provided text strictly in the requested tone and output only the transformed text.';

    /**
     * Change tone of text content using Gemini AI
     * Returns tone corrected text
     * @param targetTone - The target tone selected by the user
     * @param inputText - The text input selected by the user
     * @return String - Tone corrected text
     */
    @AuraEnabled
    public static String changeTone(String targetTone, String inputText) {
        try {            
        // Replace placeholders
        String fullPrompt = TONE_CHECKER_SYSTEM_PROMPT
            .replace('{text}', inputText)
            .replace('{target_tone}', targetTone);
            
            String result = callGeminiAPI(fullPrompt, 8192);
            return result;
            
        } catch (Exception e) {
            System.debug('Error in changeTone: ' + e.getMessage());
            throw new AuraHandledException('Error changing tone of text: ' + e.getMessage());
        }
    }

    /**
     * Call Gemini AI API to change tone of content
     * @param prompt - The prompt text to send
     * @param maxOutputTokens - Maximum number of tokens for the response
     * @return String - The generated text from Gemini AI
     */
    private static String callGeminiAPI(String prompt, Integer maxOutputTokens) {
        try {
            // Build Gemini API request structure
            Map<String, Object> geminiRequest = new Map<String, Object>{
                'contents' => new List<Object>{
                    new Map<String, Object>{
                        'parts' => new List<Object>{
                            new Map<String, Object>{
                                'text' => prompt
                            }
                        }
                    }
                },
                'generationConfig' => new Map<String, Object>{
                    'temperature' => 0.7,
                    'maxOutputTokens' => maxOutputTokens
                }
            };
            
            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:GeminiNC');
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('POST');
            // Increase timeout to 60 or 120 seconds
            req.setTimeout(120000);
            
            // Set request body
            String requestBody = JSON.serialize(geminiRequest);
            req.setBody(requestBody);
            
            System.debug('Gemini API Request Body: ' + requestBody);
            
            // Make the callout
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Response Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            
            // Handle response
            Integer statusCode = res.getStatusCode();
            
            if (statusCode == 200) {
                return parseGeminiResponse(res.getBody());
            } else if (statusCode == 429) {
                // Rate limit exceeded - parse error for details
                String errorMessage = parseErrorResponse(res.getBody());
                throw new CalloutException('Rate limit exceeded. ' + errorMessage + ' Please wait a moment and try again.');
            } else if (statusCode == 400) {
                String errorMessage = parseErrorResponse(res.getBody());
                throw new CalloutException('Bad request: ' + errorMessage);
            } else if (statusCode == 401 || statusCode == 403) {
                throw new CalloutException('Authentication failed. Please check your Gemini API key configuration.');
            } else {
                String errorMessage = parseErrorResponse(res.getBody());
                throw new CalloutException('API error (Status ' + statusCode + '): ' + errorMessage);
            }
            
        } catch (Exception e) {
            System.debug('Error calling Gemini API: ' + e.getMessage());
            throw new CalloutException('Gemini API Error: ' + e.getMessage());
        }
    }    

    /**
     * Parse the Gemini API response and extract the generated text
     * Expected response structure:
     * {
     *   "candidates": [{
     *     "content": {
     *       "parts": [{ "text": "generated text" }]
     *     }
     *   }]
     * }
     * @param responseBody - The raw JSON response from Gemini API
     * @return String - The extracted generated text
     */
    private static String parseGeminiResponse(String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        if (responseMap.containsKey('candidates')) {
            List<Object> candidates = (List<Object>) responseMap.get('candidates');
            
            if (candidates != null && !candidates.isEmpty()) {
                Map<String, Object> firstCandidate = (Map<String, Object>) candidates[0];
                
                if (firstCandidate.containsKey('content')) {
                    Map<String, Object> content = (Map<String, Object>) firstCandidate.get('content');
                    
                    if (content.containsKey('parts')) {
                        List<Object> parts = (List<Object>) content.get('parts');
                        
                        if (parts != null && !parts.isEmpty()) {
                            Map<String, Object> firstPart = (Map<String, Object>) parts[0];
                            
                            if (firstPart.containsKey('text')) {
                                String generatedText = (String) firstPart.get('text');
                                System.debug('Successfully extracted text from Gemini response');
                                return generatedText;
                            }
                        }
                    }
                }
            }
        }
        
        throw new CalloutException('Unable to extract text from Gemini response. Unexpected structure.');
    }

    /**
     * Parse error response from Gemini API
     * Expected error structure:
     * {
     *   "error": {
     *     "code": 429,
     *     "message": "Resource has been exhausted...",
     *     "status": "RESOURCE_EXHAUSTED"
     *   }
     * }
     * @param responseBody - The raw JSON error response
     * @return String - The extracted error message
     */
    private static String parseErrorResponse(String responseBody) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            if (responseMap.containsKey('error')) {
                Map<String, Object> errorObj = (Map<String, Object>) responseMap.get('error');
                
                if (errorObj.containsKey('message')) {
                    return (String) errorObj.get('message');
                }
                
                if (errorObj.containsKey('status')) {
                    return (String) errorObj.get('status');
                }
            }
            
            return responseBody;
        } catch (Exception ex) {
            return responseBody;
        }
    }
}
