# Build Extensions for Salesforce CMS

Build extensions for Salesforce CMS to boost productivity for content authors, enabling them to draft, revise, or customize their content with external tools right in the editor. For example, build extensions that enable content authors to:

* Generate content using AI tools.  
* Check content for brand voice and tone standards.  
* Add assets, such as images, from third-party Digital Asset Management (DAM) systems.

### **Considerations**

Extensions are only available to content in enhanced CMS workspaces. Previously, extensions were known as "Sidebar Extensions," and they appeared in the sidebar of the CMS content editor. Any sidebar extensions that you built or installed previously now appear in the new extensions menu, and they open in a floating panel. Test any existing extensions in the editor to make sure they work and appear as expected, specifically those that you built before Spring '26.

### **Prerequisites**

1. Familiarity with configuring and deploying [Lightning Web Components (LWC)](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-introduction.html)   
2. Familiarity with [Apex Controllers](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_apex.htm).  
3. A development environment prepared with **Salesforce DX**.  
4. An external **AI Service API key** for secure callouts.

---

### **Sample TLDR Summary Extension**

You can build extensions that work with any third-party tool. In this documentation, we'll cover the process of building an extension that integrates with an external AI service to provide a summary of existing content. This process involves developing an Apex controller with a secure callout and a Lightning Web Component (LWC) that uses specific metadata to target the CMS content editor user interface.

You can connect this type of extension to any third-party generative AI API such as Gemini or ChatGPT.

![Screenshot](screenshots/screenshot1.png)

---

## **Set up Named Credentials**

For this extension, we use named credentials for secure external API callouts to ensure that your API key isn't exposed in code. The name of the credential in the Apex Controller is tldrthis. For information and instructions about configuring a named credential, see [Named Credentials](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_named_credentials.htm).

## **Create the Apex Controller**

Create an [Apex Controller](https://www.google.com/url?q=https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_apex.htm&sa=D&source=docs&ust=1768387045891959&usg=AOvVaw2Ty1YAq3IgC5rkqj0FvNDx) to securely connect the extension to the TLDR API. Set up the callout using the named credential. The callout abstracts the API interaction to ensure security.

```java
/**
 * An apex page controller that make callout to tldr api to get the text summary
 */
public with sharing class TldrSummaryExtensionController {
    @AuraEnabled(cacheable=true)
    public static String getSummary(String summaryInputText, Integer minLength, Integer maxLength, String apiType) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:tldrthis/v1/model/extractive/summarize-text/');
        req.setHeader('content-type', 'application/json');
        req.setHeader('x-rapidapi-host', 'tldrthis.p.rapidapi.com');
        req.setMethod('POST');
        
        JSONGenerator requestBody = JSON.createGenerator(true);    
        requestBody.writeStartObject();      
        requestBody.writeStringField('text', summaryInputText);
        requestBody.writeNumberField('min_length', minLength);
        requestBody.writeNumberField('max_length', maxLength);
        requestBody.writeEndObject();
        
        req.setBody(requestBody.getAsString());
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }

    @AuraEnabled(cacheable=false)
    public static String getSummaryFromUrl(String url, Integer numSentences, Boolean isDetailed) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:tldrthis/v1/model/extractive/summarize-url/');
        req.setHeader('content-type', 'application/json');
        req.setHeader('x-rapidapi-host', 'tldrthis.p.rapidapi.com');
        req.setMethod('POST');

        JSONGenerator body = JSON.createGenerator(true);
        body.writeStartObject();
        body.writeStringField('url', url);
        body.writeNumberField('num_sentences', numSentences);
        body.writeBooleanField('is_detailed', isDetailed);
        body.writeEndObject();

        req.setBody(body.getAsString());
        Http http = new Http();
        return http.send(req).getBody();
    }
}
```

---

## **Create the Lightning Web Component (LWC)**

### **Create the Configuration File**

To make your extension visible in the CMS content editor, set targets and targetConfigs in the extension's [configuration or .js-meta.xml file](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-meta-file.html). The primary target value is lightning\_\_CmsEditorExtension, which makes the extension appear in the extensions menu in the editor. 

Set the targetConfig targets to lightning\_\_CmsEditorExtension and set the height and width attributes for the extension's floating panel. This table shows possible values for the height and width attributes.

**Height and Width Attributes**

| Attribute | Type | Description | Default |
| :---- | :---- | :---- | :---- |
| width | enum | Enter small, medium, large, or x-large. Possible values are small \= 240px medium \= 320px large \= 400px x-large \= 640px | medium |
| height | number | Enter a value between 200px and 600px. | 400px |

An extension with this targeting configuration is visible to all CMS content types, including marketing content types that support extensions.

#### Example

This example shows the configuration file of a TLDR summary extension that's available to all CMS and marketing content types that support extensions. When opened, the extension appears in a 400x400px floating panel. 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- The apiVersion may need to be updated for the current release -->
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>TLDR Summary Extension</masterLabel>
    <targets>
        <target>lightning__CmsEditorExtension</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__CmsEditorExtension">
		<size height="400" width="large"></size>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

#### **Target a Specific Content Type (e.g. News)** 

To make an extension available only to specific content types, such as News or Document, specify the contentTypes under target config for lightning\_\_CmsEditorExtension. Set the contentType fullyQualifiedName (FQN) to the FQN of the content type you want to target. To target multiple content types, list multiple content types under target config. You can target both marketing and non-marketing content types.

##### CMS Content Fully Qualified Names

| Content Type | fullyQualifiedName (FQN) |
| :---- | :---- |
| Audio | sfdc\_cms\_\_audio |
| Document | sfdc\_cms\_\_document |
| Image | sfdc\_cms\_\_image |
| News | sfdc\_cms\_\_news |
| Video | sfdc\_cms\_\_video |

##### Example 

This example shows the configuration file of an extension that's available only to the News content type. When opened, the extension appears in a 400x400px floating panel.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- The apiVersion may need to be updated for the current release -->
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>TLDR Summary Extension</masterLabel>
    <targets>
        <target>lightning__CmsEditorExtension</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__CmsEditorExtension">
		<size height="400" width="large"></size>
           <contentTypes>
		  <contentType fullyQualifiedName="sfdc_cms__news"></contentType>
          </contentTypes>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

### **Create the HTML Template**

The [HTML file](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-html-file.html) uses standard LWC markup to display the extension's user interface in the floating panel. This is where the content author interacts with the extension.

#### Example

In this example, the TLDR extension UI includes fields and buttons for selecting what part of the current content to summarize, setting length of the summary, and generating the summary. 

```html
<template>
	<div class="slds-card slds-var-p-around_x-small">
		<div class="slds-form">
			<div class="tldrIcon">
				<lightning-card variant="large" icon-name="utility:summary">
					<h6 slot="title"><b> TLDR this</b></h6>
				</lightning-card>
			</div>
			<h6><b>Create a summary for this Content Item</b></h6>
			<!-- Choose TLDR summary API you want to use -->
			<lightning-combobox name="summary" label="Choose Summarization Type" value={summaryAPIToCall} placeholder="Select Summary Type"
				options={summaryOptions} onchange={handleSummaryChange} required></lightning-combobox>

			<!-- URL mode inputs -->
			<template lwc:if={isUrlMode}>
				<lightning-input type="url" label="Article URL" value={summaryUrl}
					placeholder="https://example.com/article" onchange={handleSummaryUrlChange} required>
				</lightning-input>
				<lightning-input type="number" label="Number of Sentences" value={numSentences} min="1" max="20"
					placeholder="Enter number of sentences in summary" onchange={handleNumSentencesChange}>
				</lightning-input>
			</template>

			<!-- Text (key sentences) mode inputs -->
			<template lwc:else>
				<lightning-input type="number" label="Min Length" max="300" min="10"
					placeholder="Enter Minimum length of the output summary" onchange={handleMinLengthChange}>
				</lightning-input>
				<lightning-input type="number" label="Max Length" max="300" min="10"
					placeholder="Enter max length of the output summary" onchange={handleMaxLengthChange}>
				</lightning-input>
				<!-- Choose source field from content to pick up input data -->
				<lightning-combobox name="source" label="Choose source" value={dafInputField}
				 options={contentOptions} onchange={handleDafInputFieldChange} required>
				</lightning-combobox>
			</template>

			<!-- Choose target field from content to populate output data -->
			<lightning-combobox name="target" label="Choose target" value={dafOutputField}
			 options={contentOptions} onchange={handleDafOutputFieldChange} required>
			</lightning-combobox>
			<br>
			<lightning-button variant="brand" label="Create summary" title="Primary action" onclick={createSummary}
				class="slds-m-left_x-small"></lightning-button>	
		</div>
		<br/>
	</div>
</template>
```

---

### **Create the JavaScript File**

The [JavaScript](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-javascript.html) file defines the business logic of the extension and event handling. It uses the [experience/cmsEditorApi](https://developer.salesforce.com/docs/platform/lwc/guide/reference-experience-cms-editor-api.html) methods to read and write content. The JavaScript file also manages the integration with the Apex controller. In this case, to send the existing text to the TLDR API and get a summary.  

#### Example

This example shows the core logic of the TLDR extension, which gets content from the CMS content editor, creates a summary, and updates the content. 

```javascript
/*
 * Copyright 2022 salesforce.com, inc.
 * All Rights Reserved
 * Company Confidential
 */

import { LightningElement, wire } from 'lwc';
import {
    getContext,
    getContent,
    updateContent
} from 'experience/cmsEditorApi';

import getSummary from '@salesforce/apex/TldrSummaryExtensionController.getSummary';
import getSummaryFromUrl from '@salesforce/apex/TldrSummaryExtensionController.getSummaryFromUrl';

/**
 * This sidebar extension to get summart text using TLDR summary API. 
 * Please refer https://rapidapi.com/tldrthishq-tldrthishq-default/api/tldrthis used in this example
 */
export default class TldrSummary extends LightningElement {

    /**
     * Get the content data through wire adapter using getContent API that 
     * will help to get the current source property value in the editor
     */  
    @wire(getContent, {})
    onContent(data) {
        this.content = data;
    }

    //Get context of the editor to get schema details of current content type
    @wire(getContext)
    context;

    //Default parameter values for TLDR summary API (text mode)
    minLength = 10;
    maxLength = 300;
    summaryAPIToCall = "URL";

    //Default parameter values for URL mode
    summaryUrl = '';
    numSentences = 5;
    isDetailed = false;

    //Source field to pick up data to be summarized 
    dafInputField = "";

    //Target field to populate using API
    dafOutputField = "";

    get isUrlMode() {
        return this.summaryAPIToCall === 'URL';
    }

    //TLDR Summary Type API value set on selection
    handleSummaryChange(event) {
        this.summaryAPIToCall = event.detail.value;
    }

    get summaryOptions() {
        return [
            {
                label: 'Summarize URL',
                value: 'URL'
            },
            {
                label: 'Key sentences',
                value: 'KEY_SENTENCES'
            },
        ];
    }

    handleSummaryUrlChange(event) {
        this.summaryUrl = event.detail.value;
    }

    handleNumSentencesChange(event) {
        this.numSentences = event.detail.value;
    }

    handleDafOutputFieldChange(event) {
        this.dafOutputField = event.detail.value;
    }

    handleDafInputFieldChange(event) {
        this.dafInputField = event.detail.value;
    }

    // Selection box for current content Fields
    get contentOptions() {
        return this.getCurrentSchemaList();
    }

    //Get schema details or fields of current content selected
    getCurrentSchemaList() {
        let currentContentSchemaList = [];
        const schema = this.context.data.schema.properties
        for (const property in schema) {
            if (this._isTextType(schema[property].$ref)) {
                currentContentSchemaList.push({ label: schema[property].title, value: property})
            }
        }
        return currentContentSchemaList;
    }


    handleMinLengthChange(event) {
        this.minLength = event.detail.value;
    }

    handleMaxLengthChange(event) {
        this.maxLength = event.detail.value;
    }
    /**
     * 
     * Create a summary text by calling tldrthis api
     */
    async createSummary() {
        if (typeof this.content.data.contentBody[this.dafOutputField] == "undefined") {
            this.generateSummarizeText();
        } else {
            if (confirm("Summary Target field already has some text in it. Would you like to overwrite it?")) {
                this.generateSummarizeText();
            } else {
                console.log("Target data not modified");
            }
        }
    }

    // Method to pick up Source data -> Hit API and extract response -> Populate the target field
    async generateSummarizeText() {
        let response;

        if (this.isUrlMode) {
            if (!this.summaryUrl) {
                alert("Please enter a URL to summarize");
                return;
            }
            response = await getSummaryFromUrl({
                url: this.summaryUrl,
                numSentences: this.numSentences,
                isDetailed: this.isDetailed
            }).catch((err) => {
                console.error(err);
            });
        } else {
            var sourceHtmlInput = this.content.data.contentBody[this.dafInputField];
            if (sourceHtmlInput == undefined) {
                alert("Source input empty or not saved");
                return;
            }
            response = await getSummary({
                summaryInputText: sourceHtmlInput.replace(/<\/?[^>]+(>|$)/g, ""),
                minLength: this.minLength,
                maxLength: this.maxLength,
                apiType: this.summaryAPIToCall
            }).catch((err) => {
                console.error(err);
            });
        }

        try {
            const responseJson = JSON.parse(response);
            if (responseJson?.summary) {
                const summaryText = Array.isArray(responseJson.summary)
                    ? responseJson.summary.join(' ')
                    : responseJson.summary;

                const contentBodyModify = JSON.parse(JSON.stringify(this.content.data.contentBody));
                contentBodyModify[this.dafOutputField] = summaryText;
                updateContent({
                    contentBody: contentBodyModify
                }).then(() => {
                    //callback after daf update
                });
            } else {
                console.log('unable to get summary', responseJson?.message);
            }
        } catch (e) {
            console.error(e);
        }
    }

    _isTextType(ref) {
        return (
            ref === '#/$defs/lightning__textType' ||
            ref === '#/$defs/lightning__richTextType' ||
            ref === '#/$defs/lightning__multilineTextType'
        );
    }

}
```

---

## **Deploy Your Code and Package Your Extension**

Deploy your Apex and LWC code to your Salesforce org using one of these packaging methods. 

* **Customers and system integrators** can use [Unlocked Packages](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_intro.htm) to deploy their custom extension across their own orgs.

* **ISV Partners** should use [Second-Generation Managed Packaging (managed 2GP)](https://developer.salesforce.com/docs/atlas.en-us.pkg2_dev.meta/pkg2_dev/sfdx_dev_dev2gp.htm) to distribute and manage their extension securely on the AppExchange.

---

**See Also:**

* *Lightning Web Components Developer Guide:* [experience/cmsEditorApi](https://developer.salesforce.com/docs/platform/lwc/guide/reference-experience-cms-editor-api.html)  
* *Lightning Web Components Developer Guide:* [Define a Component](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-define.html)  
* *Salesforce Help:* [Salesforce CMS and the Digital Experiences App](https://help.salesforce.com/s/articleView?id=xcloud.community_managed_content_overview.htm&language=en_US&type=5)
