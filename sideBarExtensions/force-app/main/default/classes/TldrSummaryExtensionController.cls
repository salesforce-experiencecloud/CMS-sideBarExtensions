/**
 * An apex page controller that make callout to tldr api to get the text summary
 */
public class TldrSummaryExtensionController {
    @AuraEnabled(cacheable=true)
    public static String getSummary(String summaryInputText, Integer minLength, Integer maxLength, String apiType) {
        String urlToInvoke = 'AI'.equals(apiType)? 'v1/model/abstractive/summarize-text/': 'v1/model/extractive/summarize-text/';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:tldrthis/'+urlToInvoke);
        req.setHeader('content-type', 'application/json');
        req.setHeader('x-rapidapi-host', 'tldrthis.p.rapidapi.com');
        req.setHeader('x-rapidapi-key', '{!$Credential.Password}');
        req.setMethod('POST');
        
        //set request body with
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
}