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
        if (!this.context?.data?.schema?.properties) return [];
        let currentContentSchemaList = [];
        const schema = this.context.data.schema.properties;
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
        const outputFieldValue = this.content?.data?.contentBody?.[this.dafOutputField];
        if (typeof outputFieldValue == "undefined") {
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

                const contentBodyModify = JSON.parse(JSON.stringify(this.content?.data?.contentBody ?? {}));
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
