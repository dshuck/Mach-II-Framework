<!---
License:
Copyright 2007 GreatBizTools, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright: GreatBizTools, LLC
Author: Peter J. Farrell (peter@mach-ii.com)
$Id$

Created version: 1.6.0
Updated version: 1.6.0

Notes:
--->
<cfcomponent 
	displayname="MessageHandler"
	output="false"
	hint="Handles processing of message subscribers from publish commands.">

	<!---
	PROPERTIES
	--->
	<cfset variables.multithreaded = "" />
	<cfset variables.waitForThreads = "" />
	<cfset variables.timeout = "" />
	<cfset variables.threadingAdapter = "" />
	<cfset variables.messageSubscriberInvokers = StructNew() />
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="MessageHandler" output="false"
		hint="Initializes the handler.">
		<cfargument name="multithreaded" type="boolean" required="true" />
		<cfargument name="waitForThreads" type="boolean" required="true" />
		<cfargument name="timeout" type="numeric" required="true" />
		<cfargument name="threadingAdapter" type="MachII.util.threading.ThreadingAdapter" required="true" />

		<!--- run setters --->
		<cfset setMultithreaded(arguments.multithreaded) />
		<cfset setWaitForThreads(arguments.waitForThreads) />
		<cfset setTimeout(arguments.timeout) />
		<cfset setThreadingAdapter(arguments.threadingAdapter) />

		<cfreturn this />
 	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="handleMessage" access="public" returntype="boolean" output="false"
		hint="Handles the message.">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
		<cfset var invokers = getMessageSubscriberInvokers() />
		<cfset var threadingAdapter = getThreadingAdapter() />
		<cfset var threadIds = StructNew() />
		<cfset var publishThreadIdsInEvent = arguments.event.setArg("_publishThreadIds", StructNew()) />
		<cfset var parameters = StructNew() />
		<cfset var error = "" />
		<cfset var exception = "" />
		<cfset var continue = true />
		<cfset var i = 0 />
		
		<!--- Run in parallel if multithreaded is requested and threading is allow on this engine --->
		<cfif getMultithreaded() AND threadingAdapter.allowThreading()>
			
			<!--- Setup parameters --->
			<cfset parameters.event = arguments.event />
			
			<!--- Run all the threads --->
			<cfloop collection="#invokers#" item="i">
				<cfset threadingAdapter.run(threadIds, invokers[i], "invokeListener", parameters) />
			</cfloop>
			
			<!--- Wait and join --->
			<cfif getWaitForThreads()>
				<cfset error = threadingAdapter.join(threadIds, getTimeout()) />
				
				<!--- Create an exception --->
				<cfif IsStruct(error)>
					<cfset continue = false />
					<cfset exception = arguments.eventContext.getRequestHandler().wrapException(error) />
					<cfset arguments.eventContext.handleException(exception, true) />
				</cfif>
			<!--- Or set thread ids into the event --->
			<cfelse>
				<cfset StructAppend(publishThreadIdsInEvent, threadIds, "true") />
				<cfset arguments.event.setArg("_publishThreadIds", publishThreadIdsInEvent) />
			</cfif>
		<!--- Run in serial --->
		<cfelse>
			<cfloop collection="#invokers#" item="i">
				<cfset invokers[i].invokeListener(arguments.event) />
			</cfloop>
		</cfif>
		
		<cfreturn continue />
	</cffunction>
	
	<cffunction name="addMessageSubscriberInvoker" access="public" returntype="void" output="false"
		hint="Registers a subscriber to this message.">
		<cfargument name="messageSubscriberInvoker" type="MachII.framework.MessageSubscriberInvoker" />
		
		<cfset var key = arguments.messageSubscriberInvoker.getListenerName() & "_" & arguments.messageSubscriberInvoker.getMethod() />
		
		<cfset variables.messageSubscriberInvokers[key] = arguments.messageSubscriberInvoker />
	</cffunction>
	
	<cffunction name="getMessageSubscriberInvokers" access="public" returntype="struct" output="false"
		hint="Gets all message subscriber invokers.">
		<cfreturn variables.messageSubscriberInvokers />
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS - UTILS
	--->
	<cffunction name="getSubscriberNames" access="public" returntype="array" output="false"
		hint="Gets an array of message subscriber invoker names.">
		<cfreturn StructKeyArray(variables.messageSubscriberInvokers) />
	</cffunction>
	
	<!---
	ACCESSORS
	--->
	<cffunction name="setMultithreaded" access="private" returntype="void" output="false">
		<cfargument name="multithreaded" type="boolean" required="true" />
		<cfset variables.multithreaded = arguments.multithreaded />
	</cffunction>
	<cffunction name="getMultithreaded" access="public" returntype="boolean" output="false">
		<cfreturn variables.multithreaded />
	</cffunction>

	<cffunction name="setWaitForThreads" access="private" returntype="void" output="false">
		<cfargument name="waitForThreads" type="boolean" required="true" />
		<cfset variables.waitForThreads = arguments.waitForThreads />
	</cffunction>
	<cffunction name="getWaitForThreads" access="public" returntype="boolean" output="false">
		<cfreturn variables.waitForThreads />
	</cffunction>

	<cffunction name="setTimeout" access="private" returntype="void" output="false">
		<cfargument name="timeout" type="numeric" required="true" />
		<cfset variables.timeout = arguments.timeout />
	</cffunction>
	<cffunction name="getTimeout" access="public" returntype="numeric" output="false">
		<cfreturn variables.timeout />
	</cffunction>

	<cffunction name="setThreadingAdapter" access="private" returntype="void" output="false"
		hint="Sets a threading adapter.">
		<cfargument name="threadingAdapter" type="MachII.util.threading.ThreadingAdapter" required="true" />
		<cfset variables.threadingAdapter = arguments.threadingAdapter />
	</cffunction>
	<cffunction name="getThreadingAdapter" access="private" returntype="MachII.util.threading.ThreadingAdapter" output="false"
		hint="Gets a threading adapter.">
		<cfreturn variables.threadingAdapter />
	</cffunction>

</cfcomponent>