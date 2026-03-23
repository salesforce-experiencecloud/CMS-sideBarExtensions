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