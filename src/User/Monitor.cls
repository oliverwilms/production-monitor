Class User.Monitor Extends %SYS.Monitor.SAM.Abstract
{

/// Description
Parameter PRODUCT = "myapp";

ClassMethod ConfigTest() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    // We need to grant %DB_USER role to /api/monitor Web Application
    Set tSC = ##class(SYS.Monitor.SAM.Config).AddApplicationClass("User.Monitor", "USER")
    Quit tSC
}

ClassMethod EnableInteroperabilityMetrics() As %Status
{
    Do ##class(Ens.Util.Statistics).EnableSAMForNamespace()
    Quit $$$OK
}

Method GetSensors() As %Status
{
    Do ..SetSensor("my_counter",$Increment(^TESTmetric),"my_label")
    Quit $$$OK
}

}
