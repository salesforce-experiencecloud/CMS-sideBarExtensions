# Sample Marketing Extension: Tone Checker

For detailed, step-by-step instructions about creating an extension for Marketing content types, see *Build Extensions for Marketing Content in Marketing Cloud Next*. These code samples are for an extension that allows marketers to edit the tone of content within a selected component on the canvas. 

![Screenshot](screenshots/screenshot1.png)

## **Apex Controller**

This sample Apex controller contains the secure callout using named credentials (GeminiNC), and it connects the extension to Gemini. It can revise content in a selected component to match a specified tone. 

```java
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

```

## **Lightning Web Component**

### **Configuration File**

In this sample, the Tone Checker extension is made available only to heading components within email content. When opened, the extension appears in a 640x600px floating panel within the email builder.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- The apiVersion may need to be increased for the current release -->
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Tone Checker</masterLabel>
    <description>Refine text with AI on Heading for email content</description>
    <targets>
        <target>lightning__CmsEditorExtension</target>
    </targets> 
    <targetConfigs>
	<targetConfig targets="lightning__CmsEditorExtension">
        <size width="x-large" height="600"></size>
		<contentTypes>
			<contentType fullyQualifiedName="sfdc_cms__email">
                <blockTypes>
                    <blockType fullyQualifiedName="lightning__heading"></blockType>
                </blockTypes>
            </contentType>
		</contentTypes>
	</targetConfig>
</targetConfigs>
</LightningComponentBundle>
```

### **HTML File**

In this sample, the Tone Checker extension UI includes radio buttons for tone selection, a preview container for the revised content, and action buttons that the user can click to apply to try generating content again, or to replace the content with the revised version. 

```html
<template>
    <div class="slds-card">
        <div class="slds-form">
            <h2 class="slds-text-heading_medium slds-m-bottom_medium">Change Tone</h2>
            
            <!-- Radio button group for tone selection -->
            <lightning-radio-group
                name="toneOptions"
                label=""
                options={toneOptions}
                value={selectedTone}
                onchange={handleToneChange}
                type="radio">
            </lightning-radio-group>

            <!-- Preview text container -->
            <div class="preview-container slds-m-top_medium">
                <div class="preview-text">
                    {previewText}
                </div>
            </div>

            <!-- Action buttons -->
            <div class="slds-m-top_medium slds-align_absolute-center">
                <lightning-button
                    label="Try again"
                    icon-name="utility:refresh"
                    onclick={handleTryAgain}
                    class="slds-m-bottom_small">
                </lightning-button>
            </div>
            
            <div class="slds-align_absolute-center">
                <lightning-button
                    variant="brand"
                    label="Replace"
                    onclick={handleReplace}>
                </lightning-button>
            </div>
        </div>
    </div>
</template>
```

### **CSS File (Optional)**

Use this sample CSS file to style your Tone Checker extension. If you don't use this CSS file, your extension automatically inherits Salesforce Lightning Design System (SLDS) styles.

```css
.preview-container {
    border: 1px solid #dddbda;
    border-radius: 0.25rem;
    padding: 1rem;
    min-height: 150px;
    background-color: #ffffff;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.preview-text {
    font-size: 0.875rem;
    line-height: 1.5;
    color: #3e3e3c;
    white-space: pre-wrap;
    word-wrap: break-word;
}

.slds-card {
    padding: 1rem;
}

.slds-text-heading_medium {
    font-size: 1.25rem;
    font-weight: 700;
    color: #181818;
}
```

### **JavaScript File**

This is a sample JavaScript of the Email AI Assistant extension. It integrates with experience/blockBuilderApi methods and methods from the Apex controller. It takes the content from a selected heading component and revises it using Gemini to match the tone selected by the user. Then it can replace the content in the heading component with the revised content.  

```javascript
/*
 * Copyright 2026 salesforce.com, inc.
 * All Rights Reserved
 * Company Confidential
 */

import { LightningElement, wire } from 'lwc';
import {
    getCurrentSelectedBlock,
    replaceBlock
} from 'experience/blockBuilderApi';
import changeTone from '@salesforce/apex/ToneChecker.changeTone';

/**
 * This component allows users to change the tone of content
 * by selecting different tone options (Energetic, Professional, Straight)
 */
export default class ToneChecker extends LightningElement {
    selectedTone = '';
    previewText = '';
    originalText = '';
    block;
    isLoading = false;

    @wire(getCurrentSelectedBlock, {})
    onCurrentSelectedBlock({data}) {
        if (data) {
            this.originalText = data.attributes.text;
            this.block = JSON.parse(JSON.stringify(data));
        }
    }

    get toneOptions() {
        return [
            { label: 'Energetic', value: 'energetic' },
            { label: 'Professional', value: 'professional' },
            { label: 'Straight', value: 'straight' }
        ];
    }

    handleToneChange(event) {
        this.selectedTone = event.detail.value;
        this.generateTonedText();
    }

    handleTryAgain() {
        // Regenerate the text with the same tone
        this.generateTonedText();
    }

    handleReplace() {
        // Replace the block text on canvas with the new toned text
        if (this.previewText && this.block) {
            let _id = this.block.id;
            this.block.attributes.text = this.previewText.replace(/\n/g, '<br/>');
            
            replaceBlock(
                this.block, {
                    nodeId: _id
                }
            ).then((response) => {
                console.log('Block replaced successfully', response);
            }).catch(error => {
                console.error('Error replacing block:', error);
            });
        }
    }

    async generateTonedText() {
        if (!this.selectedTone) {
            return;
        }

        if (!this.originalText) {
            console.error('No text available to change tone');
            return;
        }

        this.isLoading = true;

        try {
            // Call Apex method to change tone
            const tonedText = await changeTone({
                targetTone: this.selectedTone,
                inputText: this.originalText
            });
            
            this.previewText = tonedText;
            console.log('Tone changed successfully');
            
        } catch (error) {
            console.error('Error changing tone:', error);
            this.previewText = 'Error generating toned text. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

}
```
