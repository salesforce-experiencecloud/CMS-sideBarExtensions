/*
 * Copyright 2026 salesforce.com, inc.
 * All Rights Reserved
 * Company Confidential
 */

public with sharing class EmailAIAssistant {
    
    // System prompt for generating email blocks in CNAVS structure format
    private static final String EMAIL_BLOCKS_SYSTEM_PROMPT = 
        'You are an expert email content generator. Generate structured email blocks based on the user\'s request. ' +
        'You MUST respond with a valid JSON object containing a subjectLine and an array of blocks.\n\n' +
        'Response format:\n' +
        '{\n' +
        '  "subjectLine": "A compelling email subject line (max 60 characters)",\n' +
        '  "blocks": [ array of block objects ]\n' +
        '}\n\n' +
        'Available block types and their exact structure:\n\n' +
        ' add text color ,textDecorationLine, fontsize; and padding as required so that the email blocks look good and professional\n'+
        '1. HEADING block (for h1, h2, h3, etc.):\n' +
        '{\n' +
        '  "attributes": {\n' +
        '    "align": "left",\n' +
        '    "lightning:colorGroup": {\n' +
        '      "textColor": "add hex code for color to look good and professional"\n' +
        '    },\n' +
        '   "lightning:padding": {\n'+
        '       "bottom": {\n' +
        '           "unit": "px",\n' +
        '           "value": 16.0 \n' +
        '       },\n' +
        '       "left": {\n' +
        '           "unit": "px",\n'+
        '           "value": 16.0\n' +
        '       },\n' +
        '       "right": {\n' +
        '           "unit": "px",\n' +
        '           "value": 16.0\n' +
        '       },\n' +
        '       "top": {\n'+
        '           "unit": "px",\n' +
        '           "value": 16.0\n' +
        '       }\n' +
        '   }\n' +
        
        '   "lightning:typography": {\n' + 
        '        "fontFamily": "{!$brand.fontFamily.arial}",\n' + 
        '        "fontSize": {\n' + 
        '            "unit": "px",\n' + 
        '            "value": 18.0\n' + 
        '        },\n' + 
        '        "fontWeight": "{!$brand.fontWeight.bold}",\n' + 
        '        "letterSpacing": "normal",\n' + 
        '        "lineHeight": 1.5,\n' + 
        '        "textDecoration": {\n' + 
        '            "textDecorationLine": [\n' + 
        '                "underline"\n' + 
        '            ]\n' + 
        '        },\n' + 
        '        "textTransform": "none"\n' + 
        '   }\n'+
        '    "text": "YOUR HEADING TEXT HERE"\n' +
        '  },\n' +
        '  "definition": "lightning/heading",\n' +
        '  "type": "block"\n' +
        '}\n\n' +
        '2. PARAGRAPH block:\n' +
        '{\n' +
        '  "attributes": {\n' +
        '    "align": "left",\n' +
        '    "lightning:colorGroup": {\n' +
        '      "textColor": "add hex code for color to look good and professional"\n' +
        '    },\n' +
        '   "lightning:padding": {\n'+
        '       "bottom": {\n' +
        '           "unit": "px",\n' +
        '           "value": 16.0 \n' +
        '       },\n' +
        '       "left": {\n' +
        '           "unit": "px",\n'+
        '           "value": 16.0\n' +
        '       },\n' +
        '       "right": {\n' +
        '           "unit": "px",\n' +
        '           "value": 16.0\n' +
        '       },\n' +
        '       "top": {\n'+
        '           "unit": "px",\n' +
        '           "value": 16.0\n' +
        '       }\n' +
        '   },\n' +
        
        '   "lightning:typography": {\n' + 
        '        "fontFamily": "{!$brand.fontFamily.arial}",\n' + 
        '        "fontSize": {\n' + 
        '            "unit": "px",\n' + 
        '            "value": 18.0\n' + 
        '        },\n' + 
        '        "fontWeight": "{!$brand.fontWeight.bold}",\n' + 
        '        "letterSpacing": "normal",\n' + 
        '        "lineHeight": 1.5,\n' + 
        '        "textDecoration": {\n' + 
        '            "textDecorationLine": [\n' + 
        '                "underline"\n' + 
        '            ]\n' + 
        '        },\n' + 
        '        "textTransform": "none"\n' + 
        '   },\n'+
        '    "text": "YOUR PARAGRAPH TEXT HERE"\n' +
        '  },\n' +
        '  "definition": "lightning/paragraph",\n' +
        '  "type": "block"\n' +
        '}\n\n' +
'3. HTML block (lightning__html) for custom images, links, and stylized text:\n' +
    '{\n' +
    '  "type": "block",\n' +
    '  "definition": "lightning/html",\n' +
    '  "attributes": {\n' +
    '    "rawHtml": "The text body of the HTML component containing HTML code",\n' +
    '    "lightning:colorGroup": {\n' +
    '      "backgroundColor": "{!$brand.colorScheme.root}",\n' +
    '      "textColor": "{!$brand.colorScheme.contrast}",\n' +
    '      "linkColor": "{!$brand.colorScheme.primaryAccent}",\n' +
    '      "borderColor": "{!$brand.colorScheme.neutral}"\n' +
    '    },\n' +
    '    "lightning:padding": "{!$brand.spacing.none}",\n' +
    '    "lightning:margin": "{!$brand.spacing.none}",\n' +
    '    "lightning:borderRadius": "{!$brand.borderRadius.square}",\n' +
    '    "lightning:borderWidth": "{!$brand.borderWeight.none}"\n' +
    '  }\n' +
    '}\n\n' +
    'Rules:\n' +
    '1. Use "rawHtml" for the content of the HTML block. \n' +
    '2. Ensure rawHtml contains valid, email-safe HTML code (images, links, styled spans). \n' +
    '3. Keep text content engaging and professional.\n' +
    '4. IMPORTANT: Return ONLY the JSON object, no markdown code blocks, no explanations.\n\n';

    /**
     * Generate email blocks (heading, paragraph, list) using Gemini AI
     * Returns structured blocks that can be injected into CNAVS email structure
     * @param prompt - The user's prompt describing what email content to generate
     * @return String - JSON containing subjectLine and blocks array
     */
    @AuraEnabled
    public static String generateEmailBlocks(String prompt) {
        try {
            if (String.isBlank(prompt)) {
                throw new AuraHandledException('Prompt is required');
            }
            
            // Combine system prompt with user prompt
            String fullPrompt = EMAIL_BLOCKS_SYSTEM_PROMPT + 'User Request:\n' + prompt;
            
            String result = callGeminiAPI(fullPrompt, 8192);
            // Clean up any markdown code blocks if present
            return cleanHtmlResponse(result);
            
        } catch (Exception e) {
            System.debug('Error in generateEmailBlocks: ' + e.getMessage());
            throw new AuraHandledException('Error generating email blocks: ' + e.getMessage());
        }
    }
    
    /**
     * Call Gemini AI API to generate content
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
     * Clean up the response by removing markdown code blocks if present
     * @param response - The raw response text
     * @return String - Cleaned content
     */
    private static String cleanHtmlResponse(String response) {
        if (String.isBlank(response)) {
            return response;
        }
        
        String cleaned = response.trim();
        
        // Remove markdown code blocks (```json ... ```, ```html ... ```, or ``` ... ```)
        if (cleaned.startsWith('```json')) {
            cleaned = cleaned.removeStart('```json').trim();
        } else if (cleaned.startsWith('```html')) {
            cleaned = cleaned.removeStart('```html').trim();
        } else if (cleaned.startsWith('```')) {
            cleaned = cleaned.removeStart('```').trim();
        }
        
        // Also handle case where just "json" prefix exists (without backticks)
        if (cleaned.startsWith('json\n')) {
            cleaned = cleaned.removeStart('json').trim();
        }
        
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.removeEnd('```').trim();
        }
        
        return cleaned;
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
