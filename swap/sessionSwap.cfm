<cfsilent>
<cfset variable.startTime = getTickCount()>
<cfparam name="attributes.type" default="read">
<cfparam name="attributes.secureCookies" default="false">

<cfparam name="attributes.ttlPart" default="d">
<cfparam name="attributes.ttlIncrement" default="-2">


<!------------------------------------------------------------------------>
<!--- set default return values ---> 
<cfparam name="request.sessionSwap.compare" default="">
<cfparam name="request.sessionSwap.loadedFromDB" default="false" type="boolean">
<cfparam name="request.sessionSwap.sessionChanged" default="false" type="boolean">
<cfparam name="request.sessionSwap.domain" default="">
<cfparam name="request.sessionSwap.ssID1" default="">
<cfparam name="request.sessionSwap.ssID2" default="">
<cfparam name="request.sessionSwap.applicationId" default="">
<cfparam name="request.sessionSwap.perf.totalTime" default="0" type="numeric">
<cfparam name="request.sessionSwap.perf.sessionReload" default="0" type="numeric">
<cfparam name="request.sessionSwap.perf.sessionWrite" default="0" type="numeric">
<cfparam name="request.sessionSwap.perf.sessionClean" default="0" type="numeric">
<!--- set default return values ---> 
<!------------------------------------------------------------------------>


<cfif NOT structKeyExists(attributes,"datasource")>
	<cfthrow type="Application" detail="Please pass in the datasource">
</cfif>

<cfscript>
// Param the domain for the cookies
if(NOT IsDefined("Attributes.Domain")){
	attributes.domain = cgi.server_name;
	}
request.sessionSwap.domain = attributes.domain;

// Server UUID
if(NOT IsDefined("application.sessionSwap.uuid")){
	application.sessionSwap.uuid = createUUID();
	}
request.sessionSwap.applicationId = application.sessionSwap.uuid;
	
function serializeObject(object){
	var local		= structNew();
	local.byteOut	= createObject("java", "java.io.ByteArrayOutputStream");
	local.byteOut.init();
	local.objOut	= createObject("java", "java.io.ObjectOutputStream");
	local.objOut.init(local.byteOut);
	local.objOut.writeObject(arguments.object);
	local.objOut.close();
	return toBase64(local.byteOut.toByteArray());
	}

function deserializeObject(objectString){
	var local = structNew();
	local.inputStream = createObject("java", "java.io.ByteArrayInputStream");
	local.objIn = createObject("java", "java.io.ObjectInputStream");
	local.returnObj = "";   
	local.inputStream.init(toBinary(arguments.objectString));
	local.objIn.init(local.inputStream);
	local.returnObj = local.objIn.readObject();
	local.objIn.close();
	return local.returnObj;
	}
</cfscript>


<!------------------------------------------------------------------------>
<!--- Default: Last Server Used --->
<cfif NOT IsDefined("Cookie.LastInstance")>
	<cfcookie name="LastInstance" value="#application.sessionSwap.uuid#" domain="#attributes.domain#" secure="#attributes.secureCookies#">
</cfif>
<!--- Default: Last Server Used --->
<!------------------------------------------------------------------------>


<!------------------------------------------------------------------------>
<!--- session identification cookies --->
<cfif NOT IsDefined("cookie._SSID1")>
	<cfcookie name="_SSID1" secure="#attributes.secureCookies#" value="#CreateUUID()#" domain="#attributes.domain#">
<cfelseif NOT isValid("UUID",cookie._SSID1)>
	<cfthrow type="Security" detail="The cookie._SSID1 was not a valid UUID format">
</cfif>
<cfif NOT IsDefined("cookie._SSID2")>
	<cfcookie name="_SSID2" secure="#attributes.secureCookies#" value="#CreateUUID()#" domain="#attributes.domain#">
<cfelseif NOT isValid("UUID",cookie._SSID2)>
	<cfthrow type="Security" detail="The cookie._SSID2 was not a valid UUID format">
</cfif>
<cfset request.sessionSwap.ssID1 = cookie._SSID1>
<cfset request.sessionSwap.ssID2 = cookie._SSID2>
<!--- session identification cookies --->
<!------------------------------------------------------------------------>


<cfswitch expression="#attributes.type#">
	
	<cfcase value="clean">
		<cfif attributes.ttlIncrement GTE 0>
			<cfthrow detail="The ttlIncrement must be less than 0">
		</cfif>
		<!--- Clear out the old session information from the database --->
		<cfquery datasource="#attributes.datasource#">
		DELETE FROM Session_Save
		WHERE change_date < <cfqueryparam cfsqltype="cf_sql_date" value="#CreateODBCDateTime(DateAdd(attributes.ttlPart,attributes.ttlIncrement,Now()))#">
		</cfquery>
		<cfset request.sessionSwap.perf.sessionClean = getTickCount() - variable.startTime>
		<cfset request.sessionSwap.perf.totalTime = request.sessionSwap.perf.totalTime + request.sessionSwap.perf.sessionClean>
	</cfcase>
	
	<cfcase value="read">
		<!--- Check to see if this is a new server --->
		<cfif cookie.lastInstance NEQ application.sessionSwap.uuid OR structKeyExists(url,"sessionSwapForceLoad")>
			<!--- Select the session information from the database --->
			<cfquery datasource="#attributes.datasource#" name="variables.sessionText">
			SELECT Session_Info
			FROM Session_Save
			WHERE
				ssid1 = <cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid1#">
					AND
				ssid2 = <cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid2#">
			</cfquery>
			<cfif variables.sessionText.recordCount GT 0>
				<cfset request.sessionSwap.loadedFromDB = true>
				<cfset variables.session = deserializeObject(variables.sessionText.session_info)>
				<!--- Clear the session structure --->
				<cfloop list="#structKeyList(Session)#" index="variables.x">
					<cfif NOT ListFindNoCase("CFID,CFTOKEN,URLTOKEN,JSESSIONID",variables.x)>
						<cfset structDelete(session,X)>
					</cfif>
				</cfloop>
				<!--- Copy over the new data into the session structure --->
				<cfloop list="#StructKeyList(variables.session)#" index="variables.x">
					<cfif NOT ListFindNoCase("CFID,CFTOKEN,URLTOKEN,JSESSIONID",variables.x)>
						<cfset "Session.#variables.x#" = Evaluate("variables.session.#variables.x#")>
					</cfif>
				</cfloop>
			</cfif>
			
		</cfif>
		<!--- Copy the session structure into the request scope to compare it later --->
		<cfset request.sessionSwap.compare = serializeObject(session)>
		
		<cfset request.sessionSwap.perf.sessionReload = getTickCount() - variable.startTime>
		<cfset request.sessionSwap.perf.totalTime = request.sessionSwap.perf.totalTime + request.sessionSwap.perf.sessionReload>
	</cfcase>
	
	<cfcase value="write">
		<!--- Serialize the Session struct into base64 Java Byte Array --->
		<cfset variables.objectString = serializeObject(session)>
		<!--- Compare the session structure to see if it has changed since the start of the request --->
		<cfif variables.objectString NEQ request.sessionSwap.compare>
			<cfset request.sessionSwap.sessionChanged = true>
			<!--- Save the information into the database --->
			<cfquery datasource="#attributes.datasource#" name="variables.checkQuery">
			SELECT ssid1
			FROM Session_Save
			WHERE
				ssid1 = <cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid1#">
					AND
				ssid2 = <cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid2#">
			</cfquery>
			<cfif variables.checkQuery.recordCount IS 0>
				<cfquery datasource="#attributes.datasource#">
				INSERT INTO session_save
					(
					session_info,
					ssid1,
					ssid2,
					change_date
					)
				VALUES
					(
					<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#variables.objectString#">,
					<cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid1#">,
					<cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid2#">,
					#createODBCDateTime(Now())#
					)
				</cfquery>
			<cfelse>
				<cfquery datasource="#attributes.datasource#">
				UPDATE session_save
				SET
					session_info = <cfqueryparam cfsqltype="CF_SQL_LONGVARCHAR" value="#variables.objectString#">,
					change_date = #CreateODBCDateTime(Now())#
				WHERE
					ssid1 = <cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid1#">
						AND
					ssid2 = <cfqueryparam cfsqltype="cf_sql_char" value="#cookie._ssid2#">
				</cfquery>
			</cfif>
			<!--- Last Server Used --->
			<cfif Cookie.LastInstance NEQ application.sessionSwap.uuid>
				<cfcookie name="LastInstance" value="#application.sessionSwap.uuid#" domain="#attributes.domain#" secure="#attributes.secureCookies#">
			</cfif>
		</cfif>
		<cfset request.sessionSwap.perf.sessionWrite = getTickCount() - variable.startTime>
		<cfset request.sessionSwap.perf.totalTime = request.sessionSwap.perf.totalTime + request.sessionSwap.perf.sessionWrite>
	</cfcase>
	
</cfswitch>
		
</cfsilent>