# Build and Deploy Sidebar Extensions in the CMS Content Editor
In Salesforce’s enhanced CMS, Sidebar Extensions put productivity tools right inside the content editor where your content creators need them. With read and write access to your content item properties, Sidebar Extensions add productivity-oriented features, such as spell checkers, grammar and tone checkers, content recommendation apps, translation services ... and anything else you can dream up. 

In this blog post, will walk you through the deployment of tldr summary extension in your own orgs.

You can add as many sidebar extensions to the content editor as your team can use. After you’ve added at least one, you see the extensions panel in the CMS on the right side of the content editor. Content authors can expand and collapse the panel and the extensions within the panel as they work.

![image](https://user-images.githubusercontent.com/59471596/180261517-a8295a30-c4ba-4ef4-a91a-0634ff0a8001.png)

# Example : Editor extension for text summarization
This repo include code sample of Editor extension for text summarization.

Let’s see how our fictitious company, Capricorn Coffee, uses Sidebar Extensions. Capricorn Coffee has many articles on their blog about their roasting process, coffee growers, and environmental commitments. They need an easy way to create article summaries to provide a short excerpt of each article. This would benefit readers and help content managers organize and repurpose content. 

A text summarizing tool would let content authors quickly create content summaries of longer articles. Capricorn decides to create an editor extension called “TLDR” that works with the TLDRthis API (https://rapidapi.com/tldrthishq-tldrthishq-default/api/tldrthis/). 


## TLDR sidebar extension user experience
With Capricorn’s TLDR sidebar extension, content authors can open a News item in the content editor, and then open the TLDR extension from the panel on the right. They set the parameters that indicate the minimum and maximum word count of the summary, select the source and target fields, and choose the summarization type (human language-like AI summarization, or a selection of key sentences). 

![image](https://user-images.githubusercontent.com/59471596/180261499-8b20df9a-bff0-409b-90ad-b53b9e0224c1.png)

After they click **Create Summary**, the extension tool runs some quick verifications and pastes a summary into the *Excerpt* field. The author verifies the summary text, makes a few tweaks as needed, and clicks *Save*. Now, a content summary is available for this News item.

Beyond TLDR, other extension tools follow a similar flow: grammar or tone checkers make suggestions based on editorial style guides, SEO tools help set and check keywords and meta descriptions, and readability tools evaluate structure and word choice to make sure content is easy to read. 

## Creating the TLDR sidebar extension

### Get the API Key
Make sure you have the API key to invoke the above TLDRthis API.

### Deploy the code to the target organization ##
This will deploys following in the above organization
1. **LWC component**  tldrSummary
2. **ApexClass** TldrSummaryExtensionController
3. **NamedCredential** tldrthis

### Update the password in NamedCredentials 
Go to Setp > NamedCredentials > Edit 'tldthis' > change password to the API key generated to access TLDRthis api
![named_credentials](https://user-images.githubusercontent.com/59471596/180263029-d6dc793b-88bd-4391-b846-2c1b75f11fc0.jpg)

