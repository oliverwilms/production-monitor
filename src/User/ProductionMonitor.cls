Include (Ensemble, EnsUI)

Class User.ProductionMonitor
{

ClassMethod GetConfigItems() As %Status
{
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSC = tStatement.%PrepareClassQuery("Ens.Config.Production","EnumerateConfigItems")
	Write tSC,!
	#Dim exp As %Exception.SystemException
	#Dim rset As %SQL.StatementResult
	Set rset = tStatement.%Execute()
	Write rset,!
	Write rset.%SQLCODE,!
	While rset.%Next() {
		// ROWSPEC = "ConfigName:%String,CommentOrClassName:%String,Enabled:%Boolean,BusinessType:%Integer,ClassName:%String,RequestClasses:%String,ResponseClasses:%String,Production:%String,ItemId:%Integer,SeqNum:%String,BusPartner:%String,Categories:%String,AlertGroups:%String"
		//Write rset.%ROWCOUNT,!
		Try {
			Set tConfigName = rset.%GetData(1)
			Set tEnabled = rset.%GetData(3)
		} Catch exp {
			Write "CATCH",!
			Write exp,!
			Write exp.DisplayString(),!
		}
		Write $Get(tConfigName)," ",$Get(tEnabled),!
	}
	Quit tSC
}

/// Get information about currently running hosts and place it into
/// <var>pInfo</var> array.
ClassMethod GetHostInfo(
	ByRef pInfo,
	ByRef pSummary) As %Status
{
	Set tSC = $$$OK
	Try {
		#; summary
		Kill tResult
		Do ##class(EnsPortal.UtilsMonitor).GetServiceSummary(.tResult,0)
		//zw tResult
	/*	
		Set pSummary("BusinessService",1) = $LB($$$Text("Last Activity"),$G(tResult("1LastActivityTime")))
		Set pSummary("BusinessService",2) = $LB($$$Text("Completed"),$FN($G(tResult("2ActivitiesCompleted")),","))
	*/
		Kill tResult
		Do ##class(EnsPortal.UtilsMonitor).GetOperationSummary(.tResult,0)
		//zw tResult
	/*
		Set pSummary("BusinessOperation",1) = $LB($$$Text("Last Activity"),$G(tResult("1LastActivityTime")))
		Set pSummary("BusinessOperation",2) = $LB($$$Text("Completed"),$FN($G(tResult("2ActivitiesCompleted")),","))
		Set pSummary("BusinessOperation",3) = $LB($$$Text("In Progress"),$FN($G(tResult("3MessagesInProgress")),","))
	*/
		#; host information
		#; run query to get stats, then group into buckets
		#dim tRS As %ResultSet
		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = "Ens.Util.Statistics"
		Set tRS.QueryName = "EnumerateHostStatus"
		//zw tRS

		Set tSC = tRS.Execute()  Quit:$$$ISERR(tSC)

		Set filteredItemCount = 0
		Set filteredErrCount = 0
	/*	
		#; List all the categories this user is allowed to view
		If ..allowedCategories '= "" {
			For c = 1:1:$Length(..allowedCategories,",") {
				Set catIndex = $Piece(..allowedCategories,",",c)
				Set tViewableCategoryArray(catIndex) = 1
			}
		}
	*/
		While (tRS.Next(.tSC)) {  Quit:$$$ISERR(tSC)
		
			Set tBucket = tRS.Data("Type")
			Set tName = tRS.Data("Name")

			#; Skip internal services
			If (tName = "EnsLib.Testing.Service")||
				(tName = "Ens.ManagerService")||
				(tName = "Ens.ScheduleService") {
				Continue
			}

			#; Skip non-matching hosts if category specified
			Set tMatch = 0
			Set tId = $Get(^Ens.Runtime("ConfigItem",tName,"%Id"),0)
			If (tId > 0) {
				Set tCategories = ##class(Ens.Config.Item).CategoryGetStored(tId)
				If ($Get(currCategory) = "") {
					#; Current category is "All"
					If ($Get(allowedCategories) = "") {
						Set tMatch = 1
					} else {
						For i=1:1:$Length(tCategories,",") {
							Set tCat = $ZStrip($Piece(tCategories,",",i),"<>WC")
							If tCat '= "" && $G(tViewableCategoryArray(tCat),0) {
								Set tMatch = 1
								Quit
							}
						}
					}
				} else {
				/*	Set tCleanedCategories=""
					For i=1:1:$Length(tCategories,",") {
						Set tCleanedCategories = tCleanedCategories_"," _ $ZStrip($Piece(tCategories,",",i),"<>WC")
					}
					Set tCategories = tCleanedCategories_","
					Set tCat = ","_%page.currCategory_","
					If tCategories [ tCat {
						Set tMatch = 1
					}
			*/	}
				If 'tMatch {
					Set filteredItemCount = filteredItemCount+1
					Set tState = $G(^CacheTemp.EnsHostMonitor($namespace,tName,"%Status"),-1)
					If (tState = "Error") {
						Set filteredErrCount = filteredErrCount+1
					}
					Continue
				}
			}
			
			Set tStatus = $ZCVT(tRS.Data("Status"),"U")
			Set tConnState = tRS.Data("AdapterState")

			#; Host status
			Set tIcon = ""
			Set tLamp = "#808080"
			Set tMsg = tStatus
			If (tStatus = "OK") {
				Set tLamp = "#80FF80"
			}
			If (tStatus = "DISABLED") {
				Set tIcon = "X"
			}
			If (tStatus = "ERROR") {
				Set tIcon = "!"
				Set tLamp = "#FF4040"
			}
			If (tStatus = "INACTIVE") {
				Set tIcon = "-"
				Set tLamp = "#FFFF80"
			}
			//Set tLamp = $Case(tStatus,"OK":"#80FF80", "ERROR":"#FF4040", "INACTIVE":"#FFFF80", :"#808080")
			//Set tIcon = $Case(tStatus,"ERROR":"!", "INACTIVE":"-", "DISABLED":"X", :"")
			//Set tMsg = $Case(tStatus,"OK":$$$Text("OK"), "ERROR":$$$Text("Error"), "INACTIVE":$$$Text("Inactive"), "":"", :tStatus)

			#; Adapter/Connection State
			Set tCIcon = "-"
			Set tCLamp = "#808080"
			If (tConnState [ " connected") {
				Set tCIcon = "+"
				Set tCLamp = "#80FF80"
			}
			If (tConnState [ " disconnected") {
				Set tCIcon = "x"
				Set tCLamp = "#FF4040"
			}
			If (tConnState [ " listening") {
				Set tCIcon = "o"
				Set tCLamp = "#FFFF80"
			}
			//Set tCLamp = $S(tConnState[" connected":"#80FF80", tConnState[" disconnected":"#FF4040", tConnState[" listening":"#FFFF80", 1:"#808080")
			//Set tCIcon = $S(tConnState[" connected":"+", tConnState[" disconnected":"x", tConnState[" listening":"o", 1:"-")

			#; compose localized Connection State text
			Set (nConn,nDis,nListen)=0
			//Set tCMsg=$Case(tConnState,"disabled":$$$Text("disabled"), "n/a":$$$Text("n/a"),"unscheduled":$$$Text("unscheduled"),"not connecting":$$$Text("no jobs"),:"")
			Set tCMsg = ""
			If (tConnState = "disabled") Set tCMsg = tConnState
			If (tConnState = "n/a") Set tCMsg = tConnState
			If (tConnState = "unscheduled") Set tCMsg = tConnState
			If (tConnState = "not connecting") Set tCMsg = tConnState
			If tCMsg="" {
				Set tState(1)=$P(tConnState,",",1)
				Set tState(2)=$P(tConnState,",",2)
				Set tState(3)=$P(tConnState,",",3)
				For i=1:1:3 {
					Set:tState(i)[" connected" nConn = +tState(i)
					Set:tState(i)[" disconnected" nDis=+tState(i)
					Set:tState(i)[" listening" nListen=+tState(i)
				}
				Set tCMsg=""
				//Set:nConn||('nDis&&'nListen) tCMsg=$Case(nConn, 1:$$$Text("1 job connected"), :$$$FormatText($$$Text("%1 jobs connected"),nConn))
				//Set tCMsg = tCMsg_$Case(nDis, 0:"", 1:$S(""=tCMsg:"",1:", ")_$$$Text("1 job disconnected"), :$$$FormatText($$$Text("%1 jobs disconnected"),nDis))
				//Set tCMsg = tCMsg_$Case(nListen, 0:"", 1:$S(""=tCMsg:"",1:", ")_$$$Text("1 job listening"), :$$$FormatText($$$Text("%1 jobs listening"),nListen))
			}
			#; Assemble sorted pInfo package
			Set tID = tName
			Set tCount = tRS.Data("Count")

			Set tSort1 = $Case(tStatus,"OK":3,"ERROR":1,:2)
			Set tSort2 = $S(nDis:1,1:2)
			If ($Get(sortMode) = "Id") {
				Set tSort3 = $G(^Ens.Runtime("ConfigItem",tName,"%Id"),tName)
			} else {
				Set tSort3 = tName
			}

			Set pInfo(tBucket,tSort1,tSort2,tSort3) = $LB(tID,tName,tMsg,tLamp,tIcon,tCount,tCLamp,tCIcon,tCMsg,)
		}
		
		Quit:$$$ISERR(tSC)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get information about currently running queues and place it into
/// <var>pInfo</var> array under "Queues".
ClassMethod GetQueueInfo(
	ByRef pInfo,
	ByRef pSummary) As %Status
{
	Set tSC = $$$OK
	Try {
		#; queue information
		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = "Ens.Queue"
		Set tRS.QueryName = "Enumerate"
		
		Set tSC = tRS.Execute()
		Quit:$$$ISERR(tSC)

		Set n = 0
		Set tTotal = 0
		While (tRS.Next(.tSC)) {
			Quit:$$$ISERR(tSC)

			Set n = n + 1
			Set tCount = tRS.Data("Count")

			#; set lamp color by count
			Set tIcon = ""
			Set tLamp = $S(tCount<1:"#00FF00", tCount<10:"#40A000", tCount<50:"#808000", tCount<200:"orange",1:"#FF4040")
			Set tType = $S(tCount<1:"Queue is Empty", tCount<10:"Under 10", tCount<50:"Under 50", tCount<200:"Under 200",1:"Over 200")
			Set:tCount>=200 tIcon = "!"

			Set tTotal = tTotal + tCount
			Set tName = tRS.Data("Name")
			Set tID = tName

			Set tSort1 = -tCount
			Set tSort2 = tName

			Set tCount = $FN(tCount,",")

			Set pInfo("Queue",tSort1,tSort2,"zzz") = $LB(tID,tName,tType,tLamp,tIcon,tCount)
		}
		Quit:$$$ISERR(tSC)

		#; find suspended messages and add to queue info
		&sql(SELECT COUNT(*) INTO :tSusCount From Ens.MessageHeader WHERE Status = 5)

		Set tName = "**Suspended Messages**"
		Set tIcon = "S"
		Set tLamp = $S(tSusCount=0:"#00FF00",1:"orange")
		Set tType = $S(tSusCount<1:"None Suspended", tSusCount<10:"Under 10", tSusCount<50:"Under 50", tSusCount<200:"Under 200",1:"Over 200")

		Set pInfo("Queue",-tSusCount,"zzz","zzz") = $LB(tName,tName,tType,tLamp,tIcon,tSusCount)
		Set tTotal = tTotal + tSusCount

		Set pSummary("Queue",1) = $LB("Total Queued Messages",$FN(tTotal,","))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod OutputTablePM(pBucket As %String = "") As %Status
{
	Set tSC = ..GetHostInfo(.pInfo)
	If (pBucket = "") Set pBucket = $Order(pInfo(pBucket))
	Set tSort1 = ""
	For {
		Set tSort1 = $Order(pInfo(pBucket,tSort1))
		If (tSort1 = "") { QUIT }
		Set tSort2 = ""
		For {
			Set tSort2 = $Order(pInfo(pBucket,tSort1,tSort2))
			If (tSort2 = "") { QUIT }
			Set tSort3 = ""
			For {
				Set tSort3 = $Order(pInfo(pBucket,tSort1,tSort2,tSort3),1,tData)
				If (tSort3 = "") { QUIT }
				Set tID = $ListGet(tData,1)
				Set tName = $ListGet(tData,2)
				Set tMsg = $ListGet(tData,3)
				Set tLamp = $ListGet(tData,4)
				Set tIcon = $ListGet(tData,5)
				Set tCount = $ListGet(tData,6)
				Set tCLamp = $ListGet(tData,7)
				Set tCIcon = $ListGet(tData,8)
				Set tCMsg = $ListGet(tData,9)
				Write "<tr>",!
				Write "<td class='Lamp' style='background:",tLamp,";'>",tIcon,"</td>",!
				Write "<td class='Lamp' style='background:",tCLamp,";'>",tCIcon,"</td>",!
				Write "<td>",tID,"</td>",!
				Write "<td style='text-align:right;' nowrap title='Number of messages processed since production start'>&nbsp;",tCount,"&nbsp;</td></tr>",!
			}
		}
	}
	Quit $$$OK
}

ClassMethod OutputTablePMQ(pBucket As %String = "") As %Status
{
	Set tSC = ..GetQueueInfo(.pInfo)
	If (pBucket = "") Set pBucket = $Order(pInfo(pBucket))
	Set tSort1 = ""
	For {
		Set tSort1 = $Order(pInfo(pBucket,tSort1))
		If (tSort1 = "") { QUIT }
		Set tSort2 = ""
		For {
			Set tSort2 = $Order(pInfo(pBucket,tSort1,tSort2))
			If (tSort2 = "") { QUIT }
			Set tSort3 = ""
			For {
				Set tSort3 = $Order(pInfo(pBucket,tSort1,tSort2,tSort3),1,tData)
				If (tSort3 = "") { QUIT }
				Set tID = $ListGet(tData,1)
				Set tName = $ListGet(tData,2)
				Set tMsg = $ListGet(tData,3)
				Set tLamp = $ListGet(tData,4)
				Set tIcon = $ListGet(tData,5)
				Set tCount = $ListGet(tData,6)
				Write "<tr>",!
				Write "<td class='Lamp' style='background:",tLamp,";'>",tIcon,"</td>",!
				Write "<td>",tID,"</td>",!
				Write "<td style='text-align:right;' nowrap title='Number of messages in this queue'>&nbsp;",tCount,"&nbsp;</td></tr>",!
			}
		}
	}
	Quit $$$OK
}

ClassMethod Test() As %Status
{
	Set tSC = ..GetHostInfo(.tStats,.tSummary)
	zw tStats
	zw tSummary
	Quit $$$OK
	
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSC = tStatement.%PrepareClassQuery("Ens.Config.Production","EnumerateConfigItems")
	Write tSC,!
	#Dim exp As %Exception.SystemException
	#Dim rset As %SQL.StatementResult
	Set rset = tStatement.%Execute()
	Write rset,!
	Write rset.%SQLCODE,!
	While rset.%Next() {
		// ROWSPEC = "ConfigName:%String,CommentOrClassName:%String,Enabled:%Boolean,BusinessType:%Integer,ClassName:%String,RequestClasses:%String,ResponseClasses:%String,Production:%String,ItemId:%Integer,SeqNum:%String,BusPartner:%String,Categories:%String,AlertGroups:%String"
		//Write rset.%ROWCOUNT,!
		Try {
			Set tConfigName = rset.%GetData(1)
			Set tEnabled = rset.%GetData(3)
		} Catch exp {
			Write "CATCH",!
			Write exp,!
			Write exp.DisplayString(),!
		}
		Write $Get(tConfigName)," ",$Get(tEnabled),!
	}
	Quit tSC
}

}
