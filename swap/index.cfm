<cfif NOT isDefined("session.testBean")>
	<cfset session.testBean = createObject("component","testBean")>
</cfif>


<cfoutput>
	
	
	<form action="saveFirstName.cfm" method="post">
		Name:<input type="text" name="firstName"/>
		<input type="submit" value="Submit"/>
	</form>
	

	<ul>
		<li><a href="#cgi.script_name#?sessionSwapForceLoad=#createUUID()#">Force reload from database</a></li>
		<li><a href="cleanOldSessions.cfm">Clean up old sessions from the database</a></li>
	</ul>
	
	<hr/>

	<cfdump var="#session#" label="session">
	<cfdump var="#cookie#" label="cookie">

	
</cfoutput>