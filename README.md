# apex-content-plugin
Oracle Apex plugin for Oracle Contents &amp; Experience Cloud (aka Documents) using applinks

Oracle Apex region plugin for Oracle Documents Cloud service (aka Content & Experience). This plugin relies on the applinks feature and allows to embed the Oracle Documents native UI in an iframe.

cd documentation : https://docs.oracle.com/en/cloud/paas/content-cloud/developer/applinks-resource.html
Limitation: works only for folders. File is not implemented yet
Prerequisites:
Subscription to Oracle Content & Experience Cloud Service (standard or Advanced)
have following informations on hand:
  Oracle identity domain the content instance is attached with
  credentials of member who is owner or manager of file or folder
  Member GUID who will be assigned with the applink (can be different form previous one)
  Folder or File GUID
