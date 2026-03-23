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
