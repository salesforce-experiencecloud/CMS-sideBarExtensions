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
