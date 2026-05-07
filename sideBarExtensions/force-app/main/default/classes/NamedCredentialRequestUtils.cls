public with sharing class NamedCredentialRequestUtils {
    private static final String MERGE_FIELD_START = '{!';
    private static final String ESCAPED_MERGE_FIELD_START = '\\u007B!';

    /**
     * Prevent Named Credential merge-field parsing in HTTP request payloads.
     */
    public static String escapeMergeFieldsInBody(String requestBody) {
        if (String.isBlank(requestBody) || !requestBody.contains(MERGE_FIELD_START)) {
            return requestBody;
        }

        return requestBody.replace(MERGE_FIELD_START, ESCAPED_MERGE_FIELD_START);
    }
}
