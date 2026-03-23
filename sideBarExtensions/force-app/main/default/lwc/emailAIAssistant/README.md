# Build Extensions for Marketing Content in Marketing Cloud Next

In Marketing Cloud Next, build extensions that are compatible with marketing content types and components to boost productivity. Marketers can use extensions to draft, revise, or customize the entire content body or individual components within a marketing asset. 

For example, build extensions that enable marketers to:

* Generate entire marketing assets or content for specific components using AI tools.  
* Check content in paragraph components for brand voice and tone standards.  
* Add assets, such as images, from third-party Digital Asset Management (DAM) systems.

### **Considerations**

In the content builder, extensions work best with non-personalized content—content that doesn't include merge fields or dynamic content variations. We recommend that content authors add merge fields or create dynamic variations after they use an extension.

Most marketing content types support extensions except for expressions and form handlers. Forms support extensions only for components within the content body, and not for fields.

**NOTE:** In this documentation, "components" and "blocks" refer to the same concept. What are called "components" in the marketing content builder UI are "blocks" in the code.

### **Prerequisites**

1. Familiarity with configuring and deploying [Lightning Web Components (LWC)](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-introduction.html)   
2. Familiarity with [Apex Controllers](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_apex.htm).  
3. A development environment prepared with **Salesforce DX**.  
4. An external **AI Service API key** for secure callouts.

### 

### **Sample AI Content Generator Extension**

You can build extensions that work with any third-party tool. In this documentation, we'll cover the process of building an extension that integrates with an external AI service to generate or refine marketing copy. This process involves developing an Apex controller with a secure callout and a Lightning Web Component (LWC) that uses specific metadata to target the CMS content editor user interface.

You can connect this type of extension to any third-party generative AI API such as Gemini or ChatGPT.

## **Set up Named Credentials**

For this extension, we use named credentials for secure external API callouts to ensure that your API key isn't exposed in code. The name of the credential in the Apex Controller is GeminiNC. For information and instructions about configuring a named credential, see [Named Credentials](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_named_credentials.htm).

## **Create the Apex Controller**

Create an [Apex Controller](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_apex.htm) to securely connect the extension to an external generative AI API. Set up the callout using the named credential. The callout abstracts the API interaction to ensure security. 

In the Apex controller, you can transform the generative AI output to ensure that it's compatible with structured marketing content. For example, to build a fully-styled Paragraph component with your extension, use the Apex controller to map the AI response directly into the JSON schema of a paragraph component. This allows the extension to return a complete, editable component rather than text only. For information about component JSON schemas, see [Reference: Component Properties and JSON Structures](#reference:-component-properties-and-json-structures).

#### Example 

This sample Apex controller contains the secure callout, and it connects the extension to a generative AI service, in this case, Gemini. It can return a fully-structured marketing email including a subject line, preheader, HTML, and structured components or blocks. 

```java
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
```

---

## **Create the Lightning Web Component (LWC)**

### **Create the Configuration File** 

To make your extension visible in the marketing content builder, set targets and targetConfigs in the extension's [configuration or .js-meta.xml file](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-meta-file.html). The primary target is lightning\_\_CmsEditorExtension, which makes the extension appear in the extensions menu in the CMS content builder. 

Set the targetConfig to lightning\_\_CmsEditorExtension and set the height and width attributes for the extension's floating panel. This table shows possible values for the height and width attributes. 

**Height and Width Attributes**

| Attribute | Type | Description | Default Value |
| :---- | :---- | :---- | :---- |
| width | enum | Enter small, medium, large, or x-large. Possible values are small \= 240px medium \= 320px large \= 400px x-large \= 640px | medium |
| height | number | Enter a value between 200px and 600px. | 400px |

An extension with this target configuration is visible to all CMS and marketing content types that support extensions. For a basic code sample, see [Build Extensions for Salesforce CMS](?tab=t.bfpcmwtthvwh#heading=h.nppn2sx0pl37).

#### 

#### **Target a Specific Content Type** 

To make your extension available only to a specific marketing content type, such as an email or landing page, specify the contentTypes under target config for lightning\_\_CmsEditorExtension. This allows your extension to interact with the entire canvas and any other properties of the content type that you're targeting, such as an email's subject line and preheader. Set the contentType fullyQualifiedName (FQN) to the desired content type's FQN. To target multiple content types, list multiple content types under target config. You can target both marketing and non-marketing content types. 

##### Marketing Content Fully Qualified Names

This table contains the FQNs of only the marketing content types that support extensions.

| Content Type | fullyQualifiedName (FQN) |
| :---- | :---- |
| Audio | sfdc\_cms\_\_audio |
| Brand | sfdc\_cms\_\_brand |
| Content Block: Email | sfdc\_cms\_\_emailFragment |
| Content Block: Landing Page | sfdc\_cms\_\_webFragment |
| Document | sfdc\_cms\_\_document |
| Email | sfdc\_cms\_\_email |
| Email Template | sfdc\_cms\_\_emailTemplate |
| Form | sfdc\_cms\_\_form |
| Image | sfdc\_cms\_\_image |
| In-App Message | sfdc\_cms\_\_inApp |
| Landing Page | sfdc\_cms\_\_landingPage |
| Landing Page Template | sfdc\_cms\_\_landingPageTemplate |
| SMS Message | sfdc\_cms\_\_sms |
| Tracked Link | sfdc\_cms\_\_trackedLink |
| Whatsapp Session | sfdc\_cms\_\_whatsappSession |
| *~~Whatsapp Message Template~~* |  |
| Video | sfdc\_cms\_\_video |

##### Example

This example shows the configuration file of a generative AI extension that's available only to email content. When opened, the extension appears in a 640x600px floating panel within the email builder.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Email AI Assistant</masterLabel>
    <description>Generate structured email blocks (h1, paragraph, ul/li) using Gemini AI that can be injected to the canvas.</description>
    <targets>
        <target>lightning__CmsEditorExtension</target>
    </targets> 
    <targetConfigs>
        <targetConfig targets="lightning__CmsEditorExtension">
            <size width="x-large" height="600"></size>
            <contentTypes>
                <contentType fullyQualifiedName="sfdc_cms__email">
                </contentType>
            </contentTypes>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

#### **Targeting a Specific Component** 

To make your extension available only to a specific component, specify the blockTypes under target config for lightning\_\_CmsEditorExtension. To make an extension available to all supported component types, don't target the extension to any specific components. 

To target the extension to a component type, set the blockType fullyQualifiedName (FQN) to the desired component's FQN. For example, to target the AI content generator to a paragraph component, set the blockType FQN to lightning\_\_paragraph. To target multiple component types, list multiple components under the target config or, if you're also targeting a specific content type, list the components under the content type. 

**Note:** Not all components are available in all content types. If you target the extension to both a component type and a content type, make sure that the component is available in the specified content type. For example, you can't target a paragraph component in an image content type.

If you specify a component type, but not a content type, your extension will be available to the component in all content types that support it. For example, if you target a heading component without specifying any content types, your extension will be available to heading components in emails, landing pages, content blocks, templates, and forms.

##### Fully Qualified Names of Components in Marketing Content

This table contains the FQNs only of the component types that support extensions.

| Component | fullyQualifiedName (FQN) |
| :---- | :---- |
| Heading | lightning\_\_heading |
| HTML | lightning\_\_html |
| Image | lightning\_\_image |
| List | lightning\_\_list |
| Paragraph | lightning\_\_paragraph |
| Button | lightning\_\_button |
| Divider | lightning\_\_divider |
| Section | lightning\_\_section |
| Column | lightning\_\_column |

##### Example

This example shows the configuration file of a generative AI extension that's available only to paragraph components in the email and landing page content types. 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Email AI Assistant</masterLabel>
    <targets>
        <target>lightning__CmsEditorExtension</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__CmsEditorExtension">
		<size height="400" width="large"></size>
           <contentTypes>
		  <contentType fullyQualifiedName="sfdc_cms__email">
                   <blockTypes>
                        <blockType fullyQualifiedName="lightning__paragraph"></blockType>
                   </blockTypes>
             </contentType>
		  <contentType fullyQualifiedName="sfdc_cms__landingPage">
                   <blockTypes>
                        <blockType fullyQualifiedName="lightning__paragraph"></blockType>
                   </blockTypes>
             </contentType>
          </contentTypes>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

### **Create the HTML File**

The [HTML file](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-html-file.html) uses standard LWC markup to display the extension's user interface (UI) in the floating panel. This is where the marketer interacts with the extension to generate content.

#### Example

In this sample, the Email AI Assistant extension UI includes an input area for an AI prompt, a button to generate content, a loading spinner, interactive controls, and two displays of the AI output. 

```html
<template>
    <div class="slds-card">
        <div class="slds-form">
            <div class="header-section">
                <h2 class="slds-text-heading_medium">Email AI Assistant</h2>
                <span class="gemini-badge">Powered by Google</span>
            </div>
            
            <p class="description">Generate structured email blocks (headings, paragraphs, lists) using AI.</p>

            <!-- Prompt input -->
            <div class="slds-m-top_medium">
                <div class="section-label slds-m-bottom_x-small">Your Prompt</div>
                <lightning-textarea
                    name="promptInput"
                    label=""
                    value={promptText}
                    placeholder="Describe the email content you want. E.g., 'Create a welcome email with a heading, introduction paragraph, and a list of 3 key features.'"
                    max-length="2000"
                    onchange={handlePromptChange}>
                </lightning-textarea>
            </div>

            <!-- Generate button -->
            <div class="slds-m-top_medium slds-align_absolute-center">
                <lightning-button
                    variant="brand"
                    label="Generate Email"
                    icon-name="utility:sparkles"
                    onclick={handleGenerate}
                    disabled={isGenerateDisabled}>
                </lightning-button>
            </div>

            <!-- Loading spinner -->
            <template lwc:if={isLoading}>
                <div class="slds-m-top_medium slds-align_absolute-center">
                    <lightning-spinner alternative-text="Generating email..." size="medium"></lightning-spinner>
                </div>
            </template>

            <!-- Generated content container -->
            <template lwc:if={hasGeneratedContent}>
                <!-- Subject Line -->
                <div class="email-field slds-m-top_medium">
                    <div class="section-label">Subject Line</div>
                    <div class="field-value">{subjectLine}</div>
                </div>

                <!-- Email Blocks -->
                <div class="content-container slds-m-top_medium">
                    <div class="content-header">
                        <div class="section-label">Email Content</div>
                        <lightning-button
                            variant="base"
                            label={previewButtonLabel}
                            icon-name={previewButtonIcon}
                            onclick={handleTogglePreview}>
                        </lightning-button>
                    </div>
                    
                    <!-- Preview mode -->
                    <template lwc:if={showPreview}>
                        <div class="preview-area">
                            <template for:each={previewBlocks} for:item="block">
                                <div key={block.key} class="preview-block">
                                    <template lwc:if={block.isHeading}>
                                        <div class="preview-heading">{block.text}</div>
                                    </template>
                                    <template lwc:if={block.isParagraph}>
                                        <div class="preview-paragraph">{block.text}</div>
                                    </template>
                                    <template lwc:if={block.isList}>
                                        <ul class="preview-list">
                                            <template for:each={block.items} for:item="item">
                                                <li key={item.key}>{item.text}</li>
                                            </template>
                                        </ul>
                                    </template>
                                </div>
                            </template>
                        </div>
                    </template>
                    
                    <!-- JSON mode -->
                    <template lwc:else>
                        <div class="code-area">
                            <pre>{generatedBlocksJson}</pre>
                        </div>
                    </template>
                </div>

                <!-- Action buttons -->
                <div class="slds-m-top_medium button-group">
                    <lightning-button
                        label="Try again"
                        icon-name="utility:refresh"
                        onclick={handleTryAgain}
                        class="slds-m-right_small">
                    </lightning-button>
                    <lightning-button
                        variant="brand"
                        label="Place on Canvas"
                        icon-name="utility:check"
                        onclick={handleReplace}
                        disabled={isReplaceDisabled}>
                    </lightning-button>
                </div>
            </template>
        </div>
    </div>
</template>
```

### ---

### **Create the CSS File**

The [CSS file](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-css-file.html) is optional. Lightning Web Components automatically inherit Salesforce Lightning Design System (SLDS) styles, but you can use a CSS file if you want custom styling within your extension. 

#### Example

Here's an example CSS file for the Email AI Assistant extension. 

```css
.slds-card {
    padding: 1rem;
    background: linear-gradient(135deg, #f8f9fa 0%, #e8f0fe 100%);
    border-radius: 0.5rem;
}

.header-section {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 0.5rem;
}

.slds-text-heading_medium {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1a73e8;
    margin: 0;
}

.gemini-badge {
    font-size: 0.7rem;
    font-weight: 500;
    color: #5f6368;
    background: linear-gradient(90deg, #4285f4, #ea4335, #fbbc04, #34a853);
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    padding: 0.25rem 0.5rem;
    border: 1px solid #dadce0;
    border-radius: 1rem;
}

.description {
    font-size: 0.85rem;
    color: #5f6368;
    margin: 0.5rem 0 0 0;
}

.section-label {
    font-size: 0.75rem;
    font-weight: 600;
    color: #1a73e8;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 0.5rem;
}

.email-field {
    border: 1px solid #dadce0;
    border-radius: 0.5rem;
    padding: 0.75rem;
    background-color: #ffffff;
}

.email-field .section-label {
    margin-bottom: 0.25rem;
}

.field-value {
    font-size: 0.9rem;
    color: #3c4043;
    line-height: 1.4;
}

.content-container {
    border: 1px solid #1a73e8;
    border-radius: 0.5rem;
    padding: 1rem;
    background-color: #ffffff;
    box-shadow: 0 2px 8px rgba(26, 115, 232, 0.15);
}

.content-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.75rem;
}

.content-header .section-label {
    margin-bottom: 0;
}

.preview-area {
    font-size: 0.875rem;
    line-height: 1.6;
    color: #3c4043;
    max-height: 300px;
    overflow-y: auto;
    padding: 0.75rem;
    background-color: #fafafa;
    border: 1px solid #e0e0e0;
    border-radius: 0.25rem;
}

.preview-block {
    margin-bottom: 0.75rem;
}

.preview-block:last-child {
    margin-bottom: 0;
}

.preview-heading {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1a1a1a;
    margin-bottom: 0.5rem;
    padding-bottom: 0.5rem;
    border-bottom: 2px solid #1a73e8;
}

.preview-paragraph {
    font-size: 0.9rem;
    color: #3c4043;
    line-height: 1.6;
}

.preview-list {
    margin: 0;
    padding-left: 1.5rem;
}

.preview-list li {
    font-size: 0.9rem;
    color: #3c4043;
    line-height: 1.8;
    margin-bottom: 0.25rem;
}

.preview-list li:last-child {
    margin-bottom: 0;
}

.code-area {
    max-height: 300px;
    overflow: auto;
    background-color: #1e1e1e;
    border-radius: 0.25rem;
    padding: 0.75rem;
}

.code-area pre {
    margin: 0;
    font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
    font-size: 0.75rem;
    line-height: 1.5;
    color: #d4d4d4;
    white-space: pre-wrap;
    word-wrap: break-word;
}

.button-group {
    display: flex;
    justify-content: center;
    gap: 0.5rem;
}

/* Style the textarea for better UX */
lightning-textarea {
    --slds-c-textarea-sizing-min-height: 100px;
}
```

---

### **Create the JavaScript File**

The [JavaScript](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-javascript.html) file defines the business logic of the extension and event handling. It can use [experience/cmsEditorApi](https://developer.salesforce.com/docs/platform/lwc/guide/reference-experience-cms-editor-api.html) methods to read and write content in an entire marketing asset, or it can use `experience/blockBuilderApi` methods to read and write content within a selected component on the canvas. 

The JavaScript file also manages the integration with the Apex controller to send the user's prompt to the generative AI model and mapping the resulting data into a format compatible with marketing content.

#### Example

This is a sample JavaScript of the Email AI Assistant extension. It integrates with [experience/cmsEditorApi](https://developer.salesforce.com/docs/platform/lwc/guide/reference-experience-cms-editor-api.html) methods and methods from the Apex controller. It takes the user input from the extension UI, sends it to the generative AI model, and programmatically updates the email to insert styled components onto the email canvas. 

This sample also includes code that manages the state of the extension using standard Salesforce CMS events actionstart and actiondone. These events are useful to make sure that marketers don't accidentally exit the extension before they're finished using it.  

```javascript
/*
 * Copyright 2026 salesforce.com, inc.
 * All Rights Reserved
 * Company Confidential
 */

import { LightningElement, wire } from 'lwc';
import {
    getContent,
    updateContent
} from 'experience/cmsEditorApi';
import generateEmailBlocks from '@salesforce/apex/EmailAIAssistant.generateEmailBlocks';

/**
 * Editor Extension component that generates email block tree using Gemini AI
 * Generates h1, paragraph, ul/li blocks that can be injected to the canvas
 */
export default class EmailAIAssistant extends LightningElement {

    contentBody = {};
    rootBlockId;
    sectionId;
    columnId;

    @wire(getContent, {})
    onContent({data}) {
        if (data) {
            console.log('Content Data', data);
            this.contentBody = data.contentBody;
            const rootBlock = data.contentBody['sfdc_cms:block'];
            this.rootBlockId = rootBlock.id;
            
            // Extract section and column IDs for block injection
            if (rootBlock.children && rootBlock.children.length > 0) {
                const section = rootBlock.children[0];
                this.sectionId = section.id;
                if (section.children && section.children.length > 0) {
                    this.columnId = section.children[0].id;
                }
            }
        }
    }

    promptText = '';
    generatedBlocks = null;
    generatedBlocksJson = '';
    subjectLine = '';
    isLoading;
    showPreview;

    get isGenerateDisabled() {
        return !this.promptText || this.promptText.trim() === '' || this.isLoading;
    }

    get isReplaceDisabled() {
        return !this.generatedBlocks || this.isLoading;
    }

    get hasGeneratedContent() {
        return this.generatedBlocks !== null;
    }

    get previewButtonLabel() {
        return this.showPreview ? 'Show JSON' : 'Show Preview';
    }

    get previewButtonIcon() {
        return this.showPreview ? 'utility:code' : 'utility:preview';
    }

    get previewBlocks() {
        if (!this.generatedBlocks) return [];
        return this.generatedBlocks.map((block, index) => this.mapBlockToPreview(block, index));
    }

    mapBlockToPreview(block, index) {
        const baseKey = `block-${index}`;
        
        if (block.definition === 'lightning/heading') {
            return {
                key: baseKey,
                isHeading: true,
                text: block.attributes.text || '',
                level: block.attributes.level || 1
            };
        } else if (block.definition === 'lightning/paragraph') {
            return {
                key: baseKey,
                isParagraph: true,
                text: block.attributes.text || ''
            };
        } else if (block.definition === 'lightning/list') {
            return {
                key: baseKey,
                isList: true,
                items: (block.attributes.items || []).map((item, i) => ({
                    key: `${baseKey}-item-${i}`,
                    text: item
                }))
            };
        }
        return { key: baseKey };
    }

    handlePromptChange(event) {
        this.promptText = event.target.value;
    }

    handleGenerate() {
        this.generateContent();
    }

    handleTryAgain() {
        this.generateContent();
    }

    handleTogglePreview() {
        this.showPreview = !this.showPreview;
    }

    handleReplace() {

        let _contentBody = JSON.parse(JSON.stringify(this.contentBody));
            
            // Get the column where we'll inject the blocks
            const rootBlock = _contentBody['sfdc_cms:block'];
            if (rootBlock.children && rootBlock.children.length > 0) {
                const section = rootBlock.children[0];
                if (section.children && section.children.length > 0) {
                    const column = section.children[0];
                    // Replace existing children with generated blocks
                    column.children = this.generatedBlocks;//this.generatedBlocksJson;
                }
            }
            _contentBody['subjectLine'] = this.subjectLine;
            updateContent({
                contentBody: _contentBody
            }).then(() => {
                console.log('Email blocks injected successfully');
                // It is safe to exit the extension now, hence dispatch the actiondone event
                this.dispatchEvent(new CustomEvent('actiondone', {
                    detail: { closeExtension: true }
                }));
            }).catch(error => {
                console.error('Error updating content:', error);
            });
    }

    async generateContent() {
        if (!this.promptText || this.promptText.trim() === '') {
            return;
        }

        this.isLoading = true;
        this.generatedBlocks = null;
        this.generatedBlocksJson = '';
        this.subjectLine = '';
        this.showPreview = true;

        try {
            // Call Apex method to generate email blocks
            const generatedContent = await generateEmailBlocks({
                prompt: this.promptText
            });
            
            // Parse the JSON response
            const parsedContent = JSON.parse(generatedContent);
            this.subjectLine = parsedContent.subjectLine || '';
            this.generatedBlocks = parsedContent.blocks || [];
            this.generatedBlocksJson = JSON.stringify(this.generatedBlocks, null, 2);
            
            console.log('Email blocks generated successfully');
            
        } catch (error) {
            console.error('Error generating email blocks:', error.message);
            this.generatedBlocks = null;
            this.generatedBlocksJson = '';
            this.subjectLine = '';
        } finally {
            this.isLoading = false;
            // The user has made changes that are not yet saved or finalized.
            // Send actionstart event to prevent accidental loss of in-progress work
            this.dispatchEvent(new CustomEvent('actionstart'));
        }
    }
}
```

---

## **Deploy Your Code and Package Your Extension**

Deploy your Apex and LWC code to your Salesforce org using one of these packaging methods. 

* **Customers and system integrators** can use [Unlocked Packages](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_intro.htm) to deploy their custom extension across their own orgs.

* **ISV Partners** should use [Second-Generation Managed Packaging (managed 2GP)](https://developer.salesforce.com/docs/atlas.en-us.pkg2_dev.meta/pkg2_dev/sfdx_dev_dev2gp.htm) to distribute and manage their extension securely on the AppExchange.

---

## **Reference: Component Properties and JSON Structures**  {#reference:-component-properties-and-json-structures}

When building an extension for marketing content, you may need to reference the properties or JSON structure of a component. The properties and JSON structures of each component compatible with extensions are described in this section.

### **Button**

A component that enables an action when clicked. Possible actions include submitting a form, opening a landing page or other web page, or initiating an email.  

**Fully Qualified Name (FQN):** lightning\_\_button

#### Properties

The lightning\_\_button contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:buttonColorGroup | buttonColorGroupType | No | Button color scheme. This is connected to the button type (sfdc\_cms:styleGroup). If a brand is selected for the marketing content, this color scheme is also inherited from the brand. |
| lightning:customCss | cssRulesType | No | An array of CSS rules. Each CSS rule consists of a selector and a declaration block. |
| lightning:horizontalAlignment | horizontalAlignmentType | No | Horizontal alignment. Possible values include left, center, right or justify. |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| lightning:typography | typographyType | No | Font of the text in the component |
| sfdc\_cms:styleGroup | buttonStyleGroupType | No | The type of the button. Can be Primary, Secondary, or Tertiary. |
| text | TextType | No | Button text |
| url | urlType | No | URL that links the button to an external website, an email address, or a phone number. Use https://, mailto:, or tel: to begin the URL. |
| width | widthType | No | Width of the button |

#### Example

This example shows the JSON structure for a lightning\_\_button component.

```json
{
  "id": "782ae2ac-5dfb-4374-98ab-4dccef4fb01f",
  "type": "block",
  "definition": "lightning/actionButton",
  "attributes": {
    "sfdc_cms:styleGroup": "{!$brand.buttonStyleGroup.primary}",
    "lightning:buttonColorGroup": "{!$brand.buttonStyleGroup.primary.lightning:buttonColorGroup}",
    "lightning:typography": "{!$brand.buttonStyleGroup.primary.lightning:typography}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:padding": "{!$brand.buttonStyleGroup.primary.lightning:padding}",
    "lightning:horizontalAlignment": "center",
    "lightning:borderRadius": "{!$brand.buttonStyleGroup.primary.lightning:borderRadius}",
    "lightning:borderWidth": "{!$brand.buttonStyleGroup.primary.lightning:borderWidth}",
    "width": "auto",
    "text": "Button"
  }
}

```

### **Column**

A subsection of a Section component. Columns are available only within a Section component, and they divide the component into side-by-side columns.

**Fully Qualified Name (FQN):** lightning\_\_column

#### Properties

The lightning\_\_column contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| columnWidth | integerType | No | Width of the column |
| lightning:backgroundImage | backgroundImageType | No | Background image of the Section component that contains the column |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:colorScheme | colorSchemeType | No | Column color scheme. This is inherited from the section that contains the column. If a brand is selected for the marketing content, this color scheme is inherited from the brand. |
| lightning:customCss | cssRulesType | No | An array of CSS rules. Each CSS rule consists of a selector and a declaration block. |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| lightning:verticalAlignment | verticalAlignmentType | No | Vertical alignment. This can be Top, Middle, or Bottom. |

#### Example

This example shows the JSON structure for a lightning\_\_column component.

```json
{
  "id": "43920ec2-d0b9-49f3-8de9-4cd1131a08fa",
  "type": "block",
  "definition": "lightning/column",
  "attributes": {
    "columnWidth": 12,
    "lightning:colorScheme": "{!$brand.colorScheme}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:padding": "{!$brand.spacing.xSmall}",
    "lightning:borderRadius": "{!$brand.borderRadius.square}",
    "lightning:borderWidth": "{!$brand.borderWeight.none}",
    "lightning:verticalAlignment": "top"
  },
  "children": [
  ]
}

```

### **Divider**

A horizontal line that visually separates components or sections in marketing content.

### 

**Fully Qualified Name (FQN):** lightning\_\_divider

#### Properties

The lightning\_\_divider contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| lightning:colorGroup | colorGroupType | No | Line color. If a brand is selected for the content, this color is inherited from the brand. |
| lightning:customCss | cssRulesType | No | An array of CSS Rules. Each CSS rule consists of a selector and a declaration block. |
| lightning:horizontalAlignment | horizontalAlignmentType | No | Horizontal alignment. Possible values include left, center, right or justify. |
| lightning:padding | spacingType | No | Component padding |
| lineStyle | textType | No | Line style. Possible values include solid, dashed, or dotted. |
| lineWeight | dimensionType | No | Line weight |
| lineWidth | dimensionType | No | Width of the line across the content body. This can be a percentage of the entire content body width (0-100%), or a value in px. |

#### Example

This example shows the JSON structure for a lightning\_\_divider component.

```json
{
              "id": "10804f55-a30c-482a-9740-75c24960009e",
              "type": "block",
              "definition": "lightning/divider",
              "attributes": {
                "lineWeight": {
                  "value": 1,
                  "unit": "px"
                },
                "lineWidth": {
                  "value": 100,
                  "unit": "%"
                },
                "lightning:colorGroup": {
                  "backgroundColor": "{!$brand.colorScheme.root}",
                  "textColor": "{!$brand.colorScheme.contrast}",
                  "linkColor": "{!$brand.colorScheme.primaryAccent}",
                  "borderColor": "{!$brand.colorScheme.neutral}"
                },
                "lightning:padding": {
                  "top": {
                    "value": 8,
                    "unit": "px"
                  },
                  "bottom": {
                    "value": 8,
                    "unit": "px"
                  },
                  "left": {
                    "value": 0,
                    "unit": "px"
                  },
                  "right": {
                    "value": 0,
                    "unit": "px"
                  }
                },
                "lightning:horizontalAlignment": "center",
                "lineStyle": "solid"
              }
            }
}
```

### **Heading**

A text-based component which can be used to title marketing content or introduce a section. 

**Fully Qualified Name (FQN)**: lightning\_\_heading

#### Properties 

The lightning\_\_heading component contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| align | textType | No | Text alignment. Possible values include left, center, right or justify. |
| level | integerType | No | Heading HTML tag. Headings enhance content readability and boost SEO for web pages. |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:colorGroup | colorGroupType | No | Component color scheme. If a brand is selected for the marketing content, this color scheme is inherited from the brand. |
| lightning:customCss | cssRulesType | No | CSS Rules is an array of CSS Rules, each CSS rule consists a selector and a declaration block |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| lightning:typography | typographyType | No | Font of the text in the component |
| text | richTextType | No | The text in the heading |
| url | urlType | No | Link the heading to a URL. |

#### Example

This example shows the JSON structure for a lightning\_\_heading component.

```json
{
              "id": "4845e304-88b7-4847-9d2f-e8b078bb8021",
              "type": "block",
              "definition": "lightning/heading",
              "attributes": {
                "lightning:typography": "{!$brand.typography.heading.heading3}",
                "lightning:colorGroup": {
                  "backgroundColor": "{!$brand.colorScheme.root}",
                  "textColor": "{!$brand.colorScheme.contrast}",
                  "linkColor": "{!$brand.colorScheme.primaryAccent}",
                  "borderColor": "{!$brand.colorScheme.neutral}"
                },
                "lightning:padding": "{!$brand.spacing.none}",
                "lightning:margin": "{!$brand.spacing.none}",
                "lightning:borderRadius": "{!$brand.borderRadius.square}",
                "lightning:borderWidth": "{!$brand.borderWeight.none}",
                "level": 3,
                "align": "left",
                "text": "Heading Example"
              }
            }

```

### **HTML**

A component for entering custom HTML code in the body of marketing content.  
**Fully Qualified Name (FQN):** lightning\_\_html

#### Properties

The lightning\_\_html component contains these properties. 

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:colorGroup | colorGroupType | No | Component color scheme. If a brand is selected for the marketing content, this color scheme is inherited from the brand. |
| lightning:padding | spacingType | No | Component padding |
| lightning:margin | spacingType | No | Component margin |
| rawHtml | htmlType | No | The text body of the HTML component. It contains HTML code. |

#### Example

This example shows the JSON structure for a lightning\_\_html component.

```json
{
  "id": "1d9773c4-48de-4ead-a381-99601c027832",
  "type": "block",
  "definition": "lightning/html",
  "attributes": {
    "lightning:colorGroup": {
      "backgroundColor": "{!$brand.colorScheme.root}",
      "textColor": "{!$brand.colorScheme.contrast}",
      "linkColor": "{!$brand.colorScheme.primaryAccent}",
      "borderColor": "{!$brand.colorScheme.neutral}"
    },
    "lightning:padding": "{!$brand.spacing.none}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:borderRadius": "{!$brand.borderRadius.square}",
    "lightning:borderWidth": "{!$brand.borderWeight.none}"
  }
}

```

### 

### **Image**

A component that contains an image from Salesforce CMS or from a URL.

**Fully Qualified Name (FQN)**: lightning\_\_image

#### Properties

The lightning\_\_image component contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| imageCaption | textType | No | Caption for the image. When included, it appears below the image. |
| imageFitConfig | objectType | No | The width of the image. This can be a percentage of the entire content body width (0-100%), or a value in px.  |
| imageInfo | imageType | No | Defines the structural requirements for rendering the image. These properties are nested within the attributes object and control the image source, location, and accessibility behavior. |
| linkUrl | urlType | No | Link the image to an external website, an email address, or a phone number. Use https://, mailto:, or tel: to begin the URL. |
| ~~linkUrlMergeField~~ | ~~textType~~ | ~~No~~ | ~~Could this be a possible merge field value in the Link URL field? Or does this relate to the option where a user can add an image via a merge field?~~ |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:colorGroup | colorGroupType | No | Component color scheme. If a brand is selected for the marketing content, this color scheme is inherited from the brand. |
| lightning:customCss | cssRulesType | No | An array of CSS Rules. Each CSS rule consists of a selector and a declaration block. |
| lightning:horizontalAlignment | horizontalAlignmentType | No | Horizontal alignment. Possible values include left, center, right or justify. |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| lightning:typography | typographyType | No | Font of the image caption |

#### Example

This example shows the JSON structure for a lightning\_\_image component.

```json
{
  "id": "1d8f443d-ea0d-45cd-a18b-f5d5408a1ef8",
  "type": "block",
  "definition": "lightning/image",
  "attributes": {
    "lightning:padding": "{!$brand.spacing.none}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:horizontalAlignment": "center",
    "lightning:typography": "{!$brand.typography.paragraph.paragraph1}",
    "lightning:colorGroup": {
      "backgroundColor": "{!$brand.colorScheme.root}",
      "textColor": "{!$brand.colorScheme.contrast}",
      "linkColor": "{!$brand.colorScheme.primaryAccent}",
      "borderColor": "{!$brand.colorScheme.neutral}"
    },
    "lightning:borderRadius": "{!$brand.borderRadius.square}",
    "lightning:borderWidth": "{!$brand.borderWeight.none}",
    "imageFitConfig": {
      "width": {
        "value": 100,
        "unit": "%"
      }
    }
  }
}

```

### **List**

A rich text component that organizes content in a list format. The list can be ordered or unordered.

**Fully Qualified Name (FQN):** lightning\_\_list

#### Properties

The lightning\_\_list contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| content | blockType | No | Text body of the list |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:colorGroup | colorGroupType | No | Component color scheme. If a brand is selected for the marketing content, this color scheme is inherited from the brand. |
| lightning:customCss | cssRulesType | No | An array of CSS rules. Each CSS rule consists of a selector and a declaration block. |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| lightning:typography | typographyType | No | Font of the text in the component |

#### Example

This example shows the JSON structure for a lightning\_\_list component.

```json
{
  "id": "41518ca1-688a-4b32-bda9-f871fe539239",
  "type": "block",
  "definition": "lightning/list",
  "attributes": {
    "lightning:typography": "{!$brand.typography.paragraph.paragraph1}",
    "lightning:colorGroup": {
      "backgroundColor": "{!$brand.colorScheme.root}",
      "textColor": "{!$brand.colorScheme.contrast}",
      "linkColor": "{!$brand.colorScheme.primaryAccent}",
      "borderColor": "{!$brand.colorScheme.neutral}"
    },
    "lightning:padding": "{!$brand.spacing.none}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:borderRadius": "{!$brand.borderRadius.square}",
    "lightning:borderWidth": "{!$brand.borderWeight.none}",
    "content": {
      "id": "d77b6e2a-bcc8-4cc3-a999-e5a6b10729e6",
      "type": "block",
      "definition": "lightning/listElement",
      "attributes": {
        "listStyle": "unordered"
      },
      "children": [
        {
          "id": "2e262932-db26-44e1-9440-d5461569ecf6",
          "type": "block",
          "definition": "lightning/paragraph",
          "attributes": {
            "text": "Your list starts here...."
          }
        }
      ]
    }
  }
}
```

### 

### **Paragraph**

A rich text component for content in a paragraph format.

**Fully Qualified Name (FQN):** lightning\_\_paragraph

#### Properties

The lightning\_\_paragraph contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| align | textType | No | Text alignment. Possible values include left, center, right or justify. |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border  |
| lightning:colorGroup | colorGroupType | No | Component color scheme. If a brand is selected for the marketing content, this color scheme is inherited from the brand. |
| lightning:customCss | cssRulesType | No | CSS Rules is an array of CSS Rules, each CSS rule consists a selector and a declaration block |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| lightning:typography | typographyType | No | Font of the text in the component |
| text | richTextType | No | The text in the paragraph. Body text can contain inline HTML tags. |

#### Example

This example shows the JSON structure for a lightning\_\_paragraph component.

```json
{
  "id": "3307d98f-1813-45d0-ab3e-9550860be0c7",
  "type": "block",
  "definition": "lightning/paragraph",
  "attributes": {
    "lightning:typography": "{!$brand.typography.paragraph.paragraph1}",
    "lightning:colorGroup": {
      "backgroundColor": "{!$brand.colorScheme.root}",
      "textColor": "{!$brand.colorScheme.contrast}",
      "linkColor": "{!$brand.colorScheme.primaryAccent}",
      "borderColor": "{!$brand.colorScheme.neutral}"
    },
    "lightning:padding": "{!$brand.spacing.none}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:borderRadius": "{!$brand.borderRadius.square}",
    "lightning:borderWidth": "{!$brand.borderWeight.none}",
    "align": "left",
    "text": "Paragraph Example"
  }
}

```

### 

### **Section**

A top-level layout component that adds structure to marketing content. Section components contain one or more columns and components. A section can't contain another section.

**Fully Qualified Name (FQN):** lightning\_\_section

#### Properties

The lightning\_\_section contains these properties.

| Property | Type | Required | Description |
| :---- | :---- | :---- | :---- |
| lightning:backgroundImage | backgroundImageType | No | Background image from Salesforce CMS |
| lightning:borderRadius | borderRadiusType | No | Shape and radius of the component border |
| lightning:borderWidth | borderWidthType | No | Width of the component border |
| lightning:colorScheme | colorSchemeType | No | Section color scheme. If a brand is selected for the marketing content, this color scheme is inherited from the brand. This scheme applies to all columns within the section. |
| lightning:customCss | cssRulesType | No | An array of CSS rules. Each CSS rule consists of a selector and a declaration block. |
| lightning:margin | spacingType | No | Component margin |
| lightning:padding | spacingType | No | Component padding |
| stackOnMobile | booleanType | No | When true, if the content is viewed on a mobile device, columns within this section are vertically stacked |

#### Example

This example shows the JSON structure for a lightning\_\_section component.

```json
{
  "id": "64ef5a50-1ce5-4fd4-a68c-74d70eb6a83b",
  "type": "block",
  "definition": "lightning/section",
  "attributes": {
    "stackOnMobile": true,
    "lightning:colorScheme": "{!$brand.colorScheme}",
    "lightning:margin": "{!$brand.spacing.none}",
    "lightning:padding": "{!$brand.spacing.xSmall}",
    "lightning:borderRadius": "{!$brand.borderRadius.square}",
    "lightning:borderWidth": "{!$brand.borderWeight.none}"
  },
  "children": [
  ]
}

```

---

**See Also:**

* *Lightning Web Components Developer Guide:* [experience/cmsEditorApi](https://developer.salesforce.com/docs/platform/lwc/guide/reference-experience-cms-editor-api.html)  
* *Salesforce Help:* [Salesforce CMS and the Digital Experiences App](https://help.salesforce.com/s/articleView?id=xcloud.community_managed_content_overview.htm&language=en_US&type=5)  
* *Salesforce Help:* [Manage Marketing Content](https://help.salesforce.com/s/articleView?id=mktg.mktg_content.htm&language=en_US&type=5)
