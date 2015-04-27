<cfcomponent>
	
	<cfset cfc.firstName = "">
	
	<cffunction name="getFirstName" access="public" returntype="string">
		<cfreturn cfc.firstName>
	</cffunction>
	<cffunction name="setFirstName" access="public" returntype="void">
		<cfargument name="firstName" type="string" required="true">
		<cfset cfc.firstName = arguments.firstName>
	</cffunction>
	
</cfcomponent>