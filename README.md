# apex-content-plugin
Oracle Apex plugin for Oracle Contents &amp; Experience Cloud (aka Documents) using applinks

Oracle Apex region plugin for Oracle Documents Cloud service (aka Content & Experience). This plugin relies on the applinks feature and allows to embed the Oracle Documents native UI in an iframe.

cd documentation : https://docs.oracle.com/en/cloud/paas/content-cloud/developer/applinks-resource.html

## Prerequisites:

Subscription to Oracle Content & Experience Cloud Service (CEC)
Instance of Oracle Apex which allows to add certificate (this is not the case for apex.oracle.com)
Install certificate with orapki
Setup wallet credentials in Apex admin interface (once)
Have valid credentials for a CEC member who is owner or manager of folders
have following informations on hand:
Oracle identity domain the content instance is attached with
credentials of member who is owner or manager of file or folder
Member GUID who will be assigned with the applink (can be different form previous one)
Folder or File GUID
Process

The plugin starts by creating an applink . A plsql code is used for calling a REST Api through https and  this is the reason why a certificate must be added previously in the db wallet. During the call, we must give:

the folder GUID,
the role assigned to the user in the apex session,
the User locale,
and the CEC member assigned to.
Once the applink has been called, the plugin get the following informations:

iframe url
Access Token
Refresh token
Then, the plugin generates specific Javascript code which fills the Div container for the iframe.

Once the APEX session is terminated, the Apex user will not be able to access to the folder. This is why Applink is well suited for contextual (in the context of an application) usage of CEC.

## Authentication

The plugin need a basic authentication which is done by the server at plsql level (Apex).

OAuth is not use because the flow implemented by CEC involve a manual login from user (through OAM).
in other words, Oauth, in this version, doesn’t implement Client Credential Oauth flow.
In the plugin, the credential will be passed as a base64 encoded value.
enter a sql statement which returns one column that contains a base64 encoded credential

ie: select ‘sjdfhkjsdhfkjshdfks–‘ key from dual
The plugin doesn’t encode in base64, therefore encoding must be done (cf below)
As a reminder, the string to be encoded is in the format of: <user>:<password> (don’t forget the “:”)
sample of query statement:

    select replace(utl_raw.cast_to_varchar2
    (utl_encode.base64_encode(
    utl_raw.cast_to_raw('USERNAME:PWD')
    )
    ),chr(13)||chr(10),'')
    from dual

## Limitations:

works only for folders. File is not implemented yet
Doesn’t work with apex.oracle.com
