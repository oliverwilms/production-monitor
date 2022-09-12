[![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/production-monitor)
 [![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fproduction-monitor&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fproduction-monitor)
 [![Reliability Rating](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fproduction-monitor&metric=reliability_rating)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fproduction-monitor)
# production-monitor

A reviewer asked what can be monitored by a monitor without a production. I have improved this app by adding a Docker container, a sample production, and an Online Demo.

## Challenge in building this image

I got an error when I tried to build image:
Unable to find/open file iris-main.log in current directory

I added ls -la at the end of Dockerfile. I saw the WORKDIR was owned by root.

## Solution

I added this into Dockerfile
```
USER root
RUN mkdir -p /home/irisowner/irisbuild && chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /home/irisowner/irisbuild
USER ${ISC_PACKAGE_MGRUSER}
```
## Online Demo
You can find online demo here - [Production Monitor](https://production-monitor.demo.community.intersystems.com/csp/user/ProductionMonitor.csp) or [Management Portal](https://production-monitor.demo.community.intersystems.com/csp/sys/UtilHome.csp)

## History

I began working on this app when I saw a post on Developer Community by Mark OReilly:

```
Hi:

Currently we are using an older Healthshare instance but I am not opposed to using IRIS as we will upgrade eventually. 

Currently for monitoring productions we have a Montior screen. We have both the Queues page and a Deepsee dashboard which has current status of our services. The issue with the Deepsee method we currently have with traffic lights is 1) the page is a bit slow to load the metrics 2) any new services from the team  a new widget needs created and although this is easy enough to do it just is time consuming. 

What I would like to achieve is at it's most basic be able to get the current list of buisness services out of the production, a bit like the tStatement.%PrepareClassQuery("Ens.Config.Production","EnumerateConfigItems") but instead of just getting enabled/disabled I would like to get the status of the components as displayed in the production monitor page, Even as just a list. So at the top of a page I can list any in the error status to make it really really clear when there is any issues. To be honest it is like a version of Production monitor page but there is a lot on there in the way it is displayed that is a bit complex for a general montior page but if could get the general stats off there to simplify things into a new once size fits all page for us would be great. 
```

## Installation ZPM

```
zpm "install production-monitor"
```

You can easily install production-manager with ZPM. I have done it with iris-mail. See screenshot below:

![screenshot](https://github.com/oliverwilms/bilder/blob/main/mail_productionMonitor.png)

Below is Production Monitor for test-data Production using OutputTablePM view

![screenshot](https://github.com/oliverwilms/bilder/blob/main/OutputTablePM.png)

Below is Production Monitor for test-data Production using OutputTableIncomingOutgoing view

![screenshot](https://github.com/oliverwilms/bilder/blob/main/OutputTableIncomingOutgoing.png)
