Class User.Monitor Extends %SYS.Monitor.SAM.Abstract
{

/// Description
Parameter PRODUCT = "myapp";

ClassMethod ConfigTest() As %Status
{
    New $NAMESPACE
    Set tNamespace = $NAMESPACE
    Set $NAMESPACE = "%SYS"
    // We need to grant %DB_USER role to /api/monitor Web Application
    Set tSC = ##class(SYS.Monitor.SAM.Config).AddApplicationClass("User.Monitor", tNamespace)
    Quit tSC
}

ClassMethod EnableInteroperabilityMetrics() As %Status
{
    Do ##class(Ens.Util.Statistics).EnableSAMForNamespace()
    Quit $$$OK
}

Method GetSensors() As %Status
{
	Set statement = ##class(%SQL.Statement).%New()
	//Set ^TESTmetric("statement") = statement
	Set status = statement.%PrepareClassQuery("Ens.Util.Statistics","EnumerateHostStatus")
	Set ^TESTmetric("%Prepare") = status  // User UnknownUser is not privileged for the operation
	If $$$ISERR(status) {
		Write "%Prepare failed:"
		Do $SYSTEM.Status.DisplayError(status)
		Quit status
	}
	Set rset = statement.%Execute()
	Set ^TESTmetric("%Execute") = status
	If (rset.%SQLCODE '= 0) {
		Write "%Execute failed:", !, "SQLCODE ", rset.%SQLCODE, ": ", rset.%Message
		Quit $$$ERROR($$$GeneralError, "SQL Error")
	}
	Do rset.%Display()
	While rset.%Next() {
		Set ^TESTmetric("%Next") = 1
		Set tName = rset.%Get("Name")
		Set tLastActivity = rset.%Get("LastActivity")
		Do ..SetSensor("my_last_activity",tLastActivity,tName)
	}
	If (rset.%SQLCODE < 0) {
		Write "%Next failed:", !, "SQLCODE ", rset.%SQLCODE, ": ", rset.%Message
		Quit $$$ERROR($$$GeneralError, "SQL Error")
	}
    Do ..SetSensor("my_counter",$Increment(^TESTmetric),"my_label")
    Quit $$$OK
}

}
