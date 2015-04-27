<cfif isDefined("form.firstName")>
	<cfset session.firstName = form.firstName>
	<cfset session.testBean.setFirstName(session.firstName)>

</cfif>

<a href="index.cfm">back</a>