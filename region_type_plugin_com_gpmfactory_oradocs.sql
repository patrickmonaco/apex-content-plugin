set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_050100 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2016.08.24'
,p_release=>'5.1.3.00.05'
,p_default_workspace_id=>1816654225478754
,p_default_application_id=>114
,p_default_owner=>'DEMO'
);
end;
/
prompt --application/ui_types
begin
null;
end;
/
prompt --application/shared_components/plugins/region_type/com_gpmfactory_oradocs
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(37212322076697157)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.GPMFACTORY.ORADOCS'
,p_display_name=>'Documents Cloud Applink'
,p_supported_ui_types=>'DESKTOP'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- GPM FACTORY - dec 2017',
'-- https://github.com/patrickmonaco/apex-content-plugin',
'-- https://gpmfactory.com',
'-- ref: https://docs.oracle.com/en/cloud/paas/content-cloud/developer/applinks-resource.html',
'-- Limitations: doesn''t implement Refresh Applink Token yet. Means that the time usage is < 15 mn',
'-- V0.1',
'',
'FUNCTION render_applink',
'    (p_region IN APEX_PLUGIN.t_region',
'    ,p_plugin IN APEX_PLUGIN.t_plugin',
'    ,p_is_printer_friendly IN BOOLEAN',
'    ) RETURN APEX_PLUGIN.t_region_render_result IS',
'',
'    SUBTYPE plugin_attr is VARCHAR2(32767);',
'    ',
'    l_result       APEX_PLUGIN.t_region_render_result;',
'    l_region       varchar2(100);',
'    l_script       varchar2(32767);',
'    l_data         APEX_APPLICATION_GLOBAL.VC_ARR2;',
'    l_js_params    varchar2(1000); ',
'    ',
'    -- Component attributes',
'    l_member        plugin_attr := p_region.attribute_01;    -- Assigned User',
'    l_guidsrc       plugin_attr := p_region.attribute_02;    -- Source for Folder/file GUID',
'    l_ifolder_id    plugin_attr := p_region.attribute_03;    -- Page item wich contains GUID',
'    l_sfolder_id    plugin_attr := p_region.attribute_04;    -- Static value of GUID',
'    l_role          plugin_attr := p_region.attribute_05;    -- Role assigned during the session',
'    l_iframeh       plugin_attr := p_region.attribute_07;    -- iframe Height',
'    l_locale        plugin_attr := p_region.attribute_08;    -- User locale for the session',
'    l_otype         plugin_attr := p_region.attribute_09;    -- Object type (Folder or file)',
'    l_domain        plugin_attr := p_region.attribute_10;    -- Identity domain for the cloud tenant',
'    l_options       plugin_attr := p_region.attribute_11;    -- Browser display options for the iframe',
'    l_cred_st       plugin_attr := p_region.attribute_12;    -- SQL statement which return Base64 encoded credentials',
'',
'    t_accesspoint  VARCHAR2(500);',
'    t_accesstoken VARCHAR2(200);',
'    t_refreshtoken VARCHAR2(200);',
'    t_applinkurl VARCHAR2(1000);',
'    t_options    VARCHAR2(200);',
'    t_base64    VARCHAR2(100);',
'    tkey VARCHAR2(100);',
'    l_rlob CLOB;',
'    payload CLOB;',
'    cr varchar2(100);',
'    t_oid VARCHAR2(100);',
'    l_values apex_json.t_values; ',
'    l_count  pls_integer; ',
'    t_column_value_list  apex_plugin_util.t_column_value_list;',
'    ',
' ',
'BEGIN',
'',
'    -- debug information will be included',
'    IF APEX_APPLICATION.g_debug then',
'        APEX_PLUGIN_UTIL.debug_region',
'          (p_plugin => p_plugin',
'          ,p_region => p_region',
'          ,p_is_printer_friendly => p_is_printer_friendly);',
'    END IF;',
'',
'-- fix a bug related to wrong value for rol',
'if l_role = ''reader'' then',
'  l_role := ''viewer'';',
'end if;',
'  ',
't_accesspoint := l_domain || ''/documents/api/1.2/applinks'';',
'',
'-- execute the sql statement which get credentials',
'-- We assume that the value returned is already Base64 encoded',
'',
't_column_value_list := apex_plugin_util.get_data(',
'            p_sql_statement    => l_cred_st,',
'            p_min_columns      => 1,',
'            p_max_columns      => 1,',
'            p_component_name   => p_region.name',
');',
't_base64 := t_column_value_list(1)(1);',
'tkey := ''Basic ''|| t_base64;',
'',
'-- Get Folder GUID if passed as a page Item or as a static value',
'',
'if l_otype = ''folder'' then',
'    if l_guidsrc = ''static'' then',
'       t_oid := l_sfolder_id;',
'    else ',
'        t_oid := V(l_ifolder_id);',
'    end if;    ',
'end if;',
'',
'-- Create an applink with a first call to Content in order to get tokens and iframe url',
'-- prepare the payload to be send',
'',
'payload := to_clob(''{',
'    "assignedUser": "'' || l_member || ''",',
'    "userLocale": "'' || l_locale ||''",',
'    "role": "'' || l_role ||''"',
'    }''',
'   );',
'   ',
'-- get credentials and prepare the header',
'-- in this case we don''t use OAUTH, because the current implementation is not suitable for server to server interaction',
'-- therefore, we use a regular Basic Auth, which means that a service account must be registerd in a dedicated table, or somewhere else.',
'',
'apex_web_service.g_request_headers(1).name := ''Content-Type'';   ',
'apex_web_service.g_request_headers(1).Value := ''application/json''; ',
'apex_web_service.g_request_headers(2).name := ''Authorization'';   ',
'apex_web_service.g_request_headers(2).Value := tkey; ',
'',
'l_rlob := APEX_WEB_SERVICE.make_rest_request(   ',
'        p_url         => t_accesspoint || ''/'' || l_otype || ''/'' || t_oid,   ',
'        p_body=> payload,   ',
'        p_http_method => ''POST''        ',
'     );  ',
'',
'apex_json.parse(p_values => l_values, ',
'                p_source => l_rlob ); ',
'l_count := apex_json.get_count( ',
'          p_path   => ''.'', ',
'          p_values => l_values ',
'   ); ',
'',
'T_ACCESSTOKEN := apex_json.get_varchar2(p_path=>''accessToken'',p0=> 1,p_values=>l_values);',
'T_REFRESHTOKEN := apex_json.get_varchar2(p_path=>''refreshToken'',p0=> 1,p_values=>l_values);',
'T_APPLINKURL := apex_json.get_varchar2(p_path=>''appLinkUrl'',p0=> 1,p_values=>l_values);',
'',
'-- Generate script which will be started once the DOM is ready',
'',
'l_script := ''',
'    var dAppLinkUrl = "'' || t_applinkurl || ''";',
'    var dAppLinkAccessToken = "'' || t_accesstoken || ''";               ',
'    var dAppLinkRefreshToken =  "'' || t_refreshtoken || ''";',
'    var dAppLinkRoleName =  "'' || l_role || ''";',
'    var dEmbedOptions = "'' || l_options || ''"; ',
'',
'    $("#content_frame").attr("src", dAppLinkUrl + dEmbedOptions);',
'            console.log(dAppLinkUrl);',
'            console.log("Role=" + dAppLinkRoleName);    ',
'    var appLink;  ',
'    function OnMessage (evt) {     ',
'        console.log("DOCSRestFilterSample: onMessage function " + evt);',
'        if (evt.data.message === "appLinkReady") {   ',
'            console.log("OnMessage invoked for appLinkReady event...");',
'            var embedPreview = "true";',
'            var iframe= document.getElementById("content_frame");',
'            var iframewindow= iframe.contentWindow ? iframe.contentWindow : iframe.contentDocument.defaultView;',
'            var msg = {',
'                message: "setAppLinkTokens",',
'                appLinkRefreshToken:dAppLinkRefreshToken,',
'                appLinkAccessToken:dAppLinkAccessToken,',
'                appLinkRoleName:dAppLinkRoleName,',
'                embedPreview:embedPreview',
'            }               ',
'            console.log("DOCSRestFilterSample: sending message to iframe with access and refresh tokens");',
'            iframewindow.postMessage(msg, "*");',
'        }',
'    };',
'        window.addEventListener && window.addEventListener("message", OnMessage, false);',
''';',
'',
'APEX_JAVASCRIPT.ADD_ONLOAD_CODE(l_script);',
'-- Generates the container that whill receive the iframe ',
'',
'htp.p(''<iframe id="content_frame"',
'          src="" ',
'         style="width: 100%; height: '' ',
'            || l_iframeh || ',
'         ''px; overflow: scroll;" frameBorder="0" >',
'         </iframe>''',
'      );',
'    ',
'return l_result;',
'END;'))
,p_api_version=>2
,p_render_function=>'render_applink'
,p_standard_attributes=>'INIT_JAVASCRIPT_CODE'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'This plugin displays the content of either a folder or a file by relying on applink feature of Oracle Content & Experience Cloud Service (formerly Oracle documents Cloud Service).',
'cd documentation : https://docs.oracle.com/en/cloud/paas/content-cloud/developer/applinks-resource.html',
'Prerequisites:',
'Subscription to Oracle Content & Experience Cloud Service (standard or Advanced)',
'have following informations on hand:',
'  Oracle identity domain the content instance is attached with',
'  credentials of member who is owner or manager of file or folder',
'  Member GUID who will be assigned with the applink (can be different form previous one)',
'  Folder or File GUID'))
,p_version_identifier=>'0.2'
,p_about_url=>'https://github.com/patrickmonaco/apex-content-plugin'
,p_files_version=>2
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37242673788225735)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Assigned User GUID'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_show_in_wizard=>false
,p_is_translatable=>false
,p_text_case=>'UPPER'
,p_examples=>'13284XXXXXXXXXXXXXXXXXXXXA8CAAAAAAAA'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Assigned user GUID must be get previously by calling the following REST api.',
'https://<TENANT>.oraclecloud.com/documents/api/1.2/users/items?info=<USERNAME>',
'It''s a regular member already registered at Content&Experience level.',
'To create an applink, the requester must have admin privileges for the folder. That is, the requester must be the owner or have the manager role.'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37219146532275650)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Source type for object GUID'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'static'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37219789027276779)
,p_plugin_attribute_id=>wwv_flow_api.id(37219146532275650)
,p_display_sequence=>10
,p_display_value=>'static'
,p_return_value=>'static'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37220193281277514)
,p_plugin_attribute_id=>wwv_flow_api.id(37219146532275650)
,p_display_sequence=>20
,p_display_value=>'Page Item'
,p_return_value=>'item'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37220784455283818)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Item for object GUID '
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>true
,p_supported_ui_types=>'DESKTOP'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(37219146532275650)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'item'
,p_help_text=>'Select the page item which contains a valid object GUID, either for a folder or a file'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37221398865290492)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Folder/File GUID'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(37219146532275650)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'static'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Enter a valid object GUID, either for a folder or a file',
'Folder or File GUID must be get previously by calling the following rest API:',
'https://<DOMAIN_ID>.documents.<AREA>.oraclecloud.com/documents/api/1.2/folders',
'or by grabbing folder id directly in the Contents UI',
'Folder or File GUI is in the similar shape : B18935D123456789123456D1FBAA684E78AC4A33A104'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37243539746229990)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>15
,p_prompt=>'Role'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'viewer'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'The three following roles are supported:',
'  Viewer: Viewers can look at files and folders, but can''t change things.',
'  Downloader: Downloaders can also download files and save them to their own computers.',
'  Contributor: Contributors can also modify files, update files, upload new files, and delete files.'))
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37315317935708771)
,p_plugin_attribute_id=>wwv_flow_api.id(37243539746229990)
,p_display_sequence=>10
,p_display_value=>'Viewer'
,p_return_value=>'viewer'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37244867657232848)
,p_plugin_attribute_id=>wwv_flow_api.id(37243539746229990)
,p_display_sequence=>20
,p_display_value=>'Contributor'
,p_return_value=>'contributor'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37245225007234421)
,p_plugin_attribute_id=>wwv_flow_api.id(37243539746229990)
,p_display_sequence=>30
,p_display_value=>'Downloader'
,p_return_value=>'downloader'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37244484484231570)
,p_plugin_attribute_id=>wwv_flow_api.id(37243539746229990)
,p_display_sequence=>50
,p_display_value=>'Reader'
,p_return_value=>'reader'
,p_is_quick_pick=>true
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37283672573817065)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_prompt=>'iframe height'
,p_attribute_type=>'INTEGER'
,p_is_required=>false
,p_is_common=>false
,p_default_value=>'600'
,p_unit=>'px'
,p_is_translatable=>false
,p_help_text=>'Height of the iframe which is used for displaying Oracle Documents'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37290552482960651)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_prompt=>'User Locale'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_show_in_wizard=>false
,p_default_value=>'English-US'
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'The user Locale which will be used for embedded UI',
'cf https://docs.oracle.com/en/cloud/paas/content-cloud/developer/applinks-resource.html'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37292586825978770)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>18
,p_prompt=>'Object Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'folder'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37293456823979914)
,p_plugin_attribute_id=>wwv_flow_api.id(37292586825978770)
,p_display_sequence=>10
,p_display_value=>'Folder'
,p_return_value=>'folder'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(37293853606980782)
,p_plugin_attribute_id=>wwv_flow_api.id(37292586825978770)
,p_display_sequence=>20
,p_display_value=>'File'
,p_return_value=>'file'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37298793935194821)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>5
,p_prompt=>'Identity Domain'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_display_length=>40
,p_is_translatable=>false
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'must be entered in the following format',
'https://xxxxxx.documents.us2.oraclecloud.com'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'must be in the following format (with https:// included) :',
'https://<tenant>.documents.<Region>.oraclecloud.com'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37324628945381906)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>110
,p_prompt=>'Display Options'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_common=>false
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'cf documentation: ',
'https://docs.oracle.com/en/cloud/paas/content-cloud/developer/embedding-web-user-interface.html#GUID-DBD4BE95-F285-4225-8B13-8454ABA57A80',
'ie:',
'?hide=header+actions&show=branding&singlesel',
'You can add individual options directly as parameters. Combine multiple hide and show options with either a plus sign (+) or comma (,)'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(37346479947096382)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>120
,p_prompt=>'Credentials Base64'
,p_attribute_type=>'SQL'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'enter a sql statement which returns one column that contains a base64 encoded credential',
'ie: select ''sjdfhkjsdhfkjshdfks--'' key from dual',
'The plugin doesn''t encode in base64, therefore encoding must be done (cf below)',
'As a reminder, the string to be encoded is in the format of:   <user>:<password> (don''t forget the ":")',
'sample of query statement',
'select replace(utl_raw.cast_to_varchar2',
'                          (utl_encode.base64_encode(',
'                                       utl_raw.cast_to_raw(''USERNAME:PWD'')',
'                           )',
'                          ),chr(13)||chr(10),'''')',
'from dual'))
);
wwv_flow_api.create_plugin_std_attribute(
 p_id=>wwv_flow_api.id(37235195103432078)
,p_plugin_id=>wwv_flow_api.id(37212322076697157)
,p_name=>'INIT_JAVASCRIPT_CODE'
,p_is_required=>false
,p_supported_ui_types=>'DESKTOP'
,p_depending_on_has_to_exist=>true
);
end;
/
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false), p_is_component_import => true);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
