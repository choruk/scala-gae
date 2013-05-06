==============
Storing Data
==============

The chief concern of most web apps, and really any app in general, is how and where to store the app's data. With GAE, you have three different options: a `basic schemaless object datastore`_, a `cloud SQL datastore`_, and an `advanced object datastore`_. The basic schemaless object datastore is where most will start and provides a very scalable option with a choice between using JDO, JPA or a low-level Datastore API. For a more advanced object datastore, Google Cloud Storage allows developers to store their data directly on Google's infrastructure with almost no limit on individual object size and a number of other amazing features. If you need a relational database, the Google Cloud SQL service is exactly what you want: a relational database in the cloud.

In the following sections, I will give examples on how to use each of the three different data storing options with Scala.

.. _basic schemaless object datastore: https://developers.google.com/appengine/docs/java/datastore/overview
.. _cloud SQL datastore: https://developers.google.com/cloud-sql/
.. _advanced object datastore: https://developers.google.com/appengine/docs/java/googlestorage/

Using the Low-Level Datastore API
---------------------------------

The low-level Datastore API gives you access to App Engine's schemaless High Replication Datastore. The Datastore holds objects, referred to as entities, each with one or more properties. Entities are grouped by kind, but two entities of the same kind don't need to have the same properties; the grouping is merely used for the purpose of queries. To retrieve information from the Datastore, you must construct a query with filter parameters to configure how the query's results are sorted. Every query needs one or more Datastore indexes, which are just tables containing entities in an order specified by the index's properties.

The sections that follow are part of a code example displaying how to:

- Generate indexes to support your app's Datastore queries.
- Use JSPs to create your apps interfaces.
- Use the low-level Datastore API to create new entities and execute queries on those entities.

.. _indexing:

A Note About Indexing
~~~~~~~~~~~~~~~~~~~~~

Any interactions you have with your app while it is running on the development server will generate indexes automatically for you as needed. These indexes will be placed inside of a file named *datastore-indexes-auto.xml* inside of a directory named *appengine-generated* in your *war/WEB-INF* directory. You can also specify your own indexes inside of a file named *datastore-indexes.xml* that you must store directly in your *war/WEB-INF* directory. A simple example of this file follows:

::

	<datastore-indexes autoGenerate="true">

	    <datastore-index kind="Greeting" ancestor="true">
	        <property name="date" direction="desc"/>
	    </datastore-index>

	</datastore-indexes>

The outer *<datastore-indexes>* tag is the wrapper you place around all of the indexes you wish to declare. The *autoGenerate="true"* attribute specifies that you want GAE to take both indexes in this file as well as in the *datastore-indexes-auto.xml* file into account when you are uploading your app. This attribute is important because if a user tries to navigate to a page where a query is executed for which you have no index, the page will fail to load and the index will only then begin to be generated. This process takes some time and user experience will suffer greatly.

If you wish to simulate the behavior of the production environment, you can set *autoGenerate* to "false" in your *datastore-indexes.xml* file and when a query can't be satisfied on your development server, a DatastoreNeedIndexException will be thrown. The exception will also list both the minimal index and the index it would have auto-generated. For a more in-depth discussion of index selection, see `this article`_.

.. _this article: https://developers.google.com/appengine/articles/indexselection

The Deployment Descriptor
~~~~~~~~~~~~~~~~~~~~~~~~~

The deployment descriptor file for this code example looks like this:

::

	<web-app xmlns="http://java.sun.com/xml/ns/javaee" version="2.5">
	    <servlet>
	        <servlet-name>sign</servlet-name>
	        <servlet-class>guestbook.SignGuestbookServlet</servlet-class>
	    </servlet>
	    <servlet-mapping>
	        <servlet-name>sign</servlet-name>
	        <url-pattern>/sign</url-pattern>
	    </servlet-mapping>
	    <welcome-file-list>
	        <welcome-file>guestbook.jsp</welcome-file>
	    </welcome-file-list>
	</web-app>

Notice that the welcome file is not a servlet, but a JSP file. More on that in the next section.

Creating the User Interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The user interface for this code example is created in a JSP file to avoid having the servlet code get too messy and to introduce more modularity. The file, named *guestbook.jsp*, looks like this:

::

	<%@ page contentType="text/html;charset=UTF-8" language="java" %>
	<%@ page import="java.util.List" %>
	<%@ page import="com.google.appengine.api.users.User" %>
	<%@ page import="com.google.appengine.api.users.UserService" %>
	<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
	<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
	<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
	<%@ page import="com.google.appengine.api.datastore.Query" %>
	<%@ page import="com.google.appengine.api.datastore.Entity" %>
	<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
	<%@ page import="com.google.appengine.api.datastore.Key" %>
	<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
	<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

	<html>
	  <head>
	    <link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
	  </head>

	  <body>

	    <%
	      String guestbookName = request.getParameter("guestbookName");
	      if (guestbookName == null) {
	        guestbookName = "default";
	      }
	      pageContext.setAttribute("guestbookName", guestbookName);

	      UserService userService = UserServiceFactory.getUserService();
	      User user = userService.getCurrentUser();
	      if (user != null) {
	        pageContext.setAttribute("user", user);
	    %>
	        <p>Hello, ${fn:escapeXml(user.nickname)}! (You can <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign out</a>.)</p>
	    <%
	      } else {
	    %>
	        <p>Hello! <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign in</a> to include your name with greetings you post.</p>
	    <%
	      }
	    %>

	    <%
	      DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	      Key guestbookKey = KeyFactory.createKey("Guestbook", guestbookName);

	      // Run an ancestor query to ensure we see the most up-to-date
	      // view of the Greetings belonging to the selected Guestbook.
	      Query query = new Query("Greeting", guestbookKey).addSort("date", Query.SortDirection.DESCENDING);
	      List<Entity> greetings = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(5));
	      if (greetings.isEmpty()) {
	    %>
	        <p>Guestbook '${fn:escapeXml(guestbookName)}' has no messages.</p>
	    <%
	      } else {
	    %>
	        <p>Messages in Guestbook '${fn:escapeXml(guestbookName)}'.</p>
	    <%
	        for (Entity greeting : greetings) {
	          pageContext.setAttribute("greeting_content", greeting.getProperty("content"));
	          if (greeting.getProperty("user") == null) {
	    %>
	            <p>An anonymous person wrote:</p>
	    <%
	          } else {
	            pageContext.setAttribute("greeting_user", greeting.getProperty("user"));
	    %>
	            <p><b>${fn:escapeXml(greeting_user.nickname)}</b> wrote:</p>
	    <%
	          }
	    %>
	          <blockquote>${fn:escapeXml(greeting_content)}</blockquote>
	    <%
	        }
	      }
	    %>

	    <form action="/sign" method="post">
	      <div><textarea name="content" rows="3" cols="60"></textarea></div>
	      <div><input type="submit" value="Post Greeting" /></div>
	      <input type="hidden" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/>
	    </form>

	    <form action="/guestbook.jsp" method="get">
	      <div><input type="text" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/></div>
	    	<div><input type="submit" value="Switch Guestbook"/></div>
	    </form>

	  </body>
	</html>

The Datastore query executed to retrieve all of the entries in a guestbook requires a Datastore index that you have already seen in the indexing_ section. The query is executed with the call to prepare() and the result is filtered to only include the 5 most recent entries, which are then displayed on the webpage.

Creating New Guestbook Entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The sign servlet is where new guestbook entries are created. The code for the sign servlet looks like this:

::

	package guestbook

	import java.util.logging.Logger
	import java.util.Date
	import javax.servlet.http.{HttpServlet, HttpServletRequest => HSReq, HttpServletResponse => HSResp}
	import com.google.appengine.api.users.{User, UserService => UServ, UserServiceFactory => UServFactory}
	import com.google.appengine.api.datastore.{DatastoreService, DatastoreServiceFactory => DSFactory, Entity, Key, KeyFactory}

	class SignGuestbookServlet extends HttpServlet
	{
	    val log = Logger.getLogger("SignGuestbookServlet")

	    override def doPost( req : HSReq, resp : HSResp)
	    {
	      val userService = UServFactory.getUserService()
	      val user = userService.getCurrentUser()

	      val guestbookName = req.getParameter("guestbookName")
	      val guestbookKey = KeyFactory.createKey("Guestbook",guestbookName)
	      val content = req.getParameter("content")
	      val date = new Date()

	      val greeting = new Entity("Greeting",guestbookKey)
	      greeting.setProperty("user",user)
	      greeting.setProperty("date",date)
	      greeting.setProperty("content",content)

	      val datastore = DSFactory.getDatastoreService()
	      datastore.put(greeting)
			log.info("Just created new entry in guestbook: " + content + "\nfrom user: " + user)

	      resp.sendRedirect("/guestbook.jsp?guestbookName=" + guestbookName)
	    }
	}

Here you can see a new entity, a "Greeting" entity, is created using the key specific to the name of the guestbook that the user posted in. The name of the user, the current date and time, and the content of the post are all stored with the entity and a message is logged to the INFO level displaying the content of the message and the name of the user that posted it.

Using the Google Cloud SQL API
------------------------------

Google Cloud SQL is a service that lets you locate your MySQL Databases in Google's cloud. GAE support of Google Cloud SQL is currently experimental, but you can currently try it out for free until next month (June 2013). If you need a relational database for your GAE app, Google Cloud SQL is your answer. There is one key difference to note from the other database options when you are using the Google Cloud SQL service: you must have your own local MySQL instance configured in order to mirror the Google Cloud SQL service during development.

To set up your app to use the Google Cloud SQL service, you need to follow the instructions in the first two sections of `this Google documentation`_. You also need to make sure you have `downloaded the mysql-connector-java.jar`_ and placed it inside of your *appengine-java-sdk/lib/impl* directory.

.. _this Google documentation: https://developers.google.com/appengine/docs/java/cloud-sql/developers-guide
.. _downloaded the mysql-connector-java.jar: http://dev.mysql.com/downloads/connector/j/

Modifying the Ant Build File
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before we look at the Google Cloud SQL API in use, we need to make a slight modification to the "runserver" target defined in our *buid.xml* file. In order to be able to use Google Cloud SQL services on the development server, we need to pass a few extra command line arguments to the call to launch the development server. The target now looks like this:

::

	<target name="runserver" depends="compile" description="Starts the development server.">
       <dev_appserver war="war" port="8888">
					<options>
						<arg value="--jvm_flag=-Drdbms.server=local" />
						<arg value="--jvm_flag=-Drdbms.driver=com.mysql.jdbc.Driver" />
						<arg value="--jvm_flag=-Drdbms.url=jdbc:mysql://localhost:3306/yourdatabase?user=root" />
					</options>
				</dev_appserver>
   </target>

These three new flags tell the development server to use the local MySQL instance inside of the database named "yourdatabase" with the root user. If you wanted to log in with an account other than the root user, simply replace the string after the question mark with *username=userName&amp;password=password*, replacing *userName* with your desired user name and *password* with the password for that user.

Creating the User Interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The user interface will once again be created using JSPs for all the same reasons as before, however this time the app itself has changed slightly: users can no longer switch between different guestbooks while posting messages. The main reason behind this change is due to the use of a relational database and the fact that we can no longer create new "groupings" or database tables on the fly. The code looks like this:

::

	<%@ page contentType="text/html;charset=UTF-8" language="java" %>
	<%@ page import="java.util.List" %>
	<%@ page import="java.sql.*" %>
	<%@ page import="com.google.appengine.api.rdbms.AppEngineDriver" %>
	<%@ page import="com.google.appengine.api.users.User" %>
	<%@ page import="com.google.appengine.api.users.UserService" %>
	<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
	<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

	<html>
		<head>
	  	<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
		</head>
	  <body>

	  <%
		UserService userService = UserServiceFactory.getUserService();
	    	User user = userService.getCurrentUser();
	    	if (user != null) {
	      	pageContext.setAttribute("user", user);
	  %>
	      <p>Hello, ${fn:escapeXml(user.nickname)}! (You can <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign out</a>.)</p>
	  <%
	    	} else {
	  %>
	      <p>Hello! <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign in</a> to include your name with greetings you post.</p>
	  <%
	    }
	  %>

	<%
			Connection connection = null;
			connection = DriverManager.getConnection("jdbc:google:rdbms://instance_name/guestbook");
			ResultSet resultSet = connection.createStatement().executeQuery("SELECT guestName, content, entryID FROM entries");
	%>

			<table style="border: 1px solid black">
				<tbody>
					<tr>
						<th width="35%" style="background-color: #CCFFCC; margin: 5px">Name</th>
						<th style="background-color: #CCFFCC; margin: 5px">Message</th>
						<th style="background-color: #CCFFCC; margin: 5px">ID</th>
					</tr>
		<%
					while (resultSet.next())
					{
					    String guestName = resultSet.getString("guestName");
					    String content = resultSet.getString("content");
					    int id = resultSet.getInt("entryID");
		%>

					<tr>
						<td><%= guestName %></td>
						<td><%= content %></td>
						<td><%= id %></td>
					</tr>

		<%
					}
					connection.close();
		%>

				</tbody>
			</table>
			<br />
			No more messages!
			<p><strong>Sign the guestbook!</strong></p>
			<form action="/sign" method="post">
			    <div>Message:
			    <br /><textarea name="content" rows="3" cols="60"></textarea>
			    </div>
			    <div><input type="submit" value="Post Greeting" /></div>
			    <input type="hidden" name="guestbookName" />
			</form>
	  </body>
	</html>

The important part of this code is where a new *Connection* object is created. At the call to *DriverManager*'s *getConnection()* method, you would need to replace "instance_name" with the name of your Google Cloud SQL instance and "guestbook" with the name of the database you wish to establish a connection to. A SQL query is then executed to retrieve all of the entries in the entries table of the guestbook database before they are displayed.

Creating New Guestbook Entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The sign servlet is where new guestbook entries are created. The code for the sign servlet looks like this:

::

	package guestbook

	import com.google.appengine.api.rdbms.AppEngineDriver
	import java.util.logging.Logger
	import java.util.Date
	import javax.servlet.http.{HttpServlet, HttpServletRequest => HSReq, HttpServletResponse => HSResp}
	import com.google.appengine.api.users.{User, UserService => UServ, UserServiceFactory => UServFactory}
	import java.sql._

	class SignGuestbookServlet extends HttpServlet
	{
	    val log = Logger.getLogger("SignGuestbookServlet")

	    override def doPost( req : HSReq, resp : HSResp)
	    {
			val out = resp.getWriter()
			var connection:Connection = null
			val userService = UServFactory.getUserService()
			val user = userService.getCurrentUser()
		   try {
		   	DriverManager.registerDriver(new AppEngineDriver())
		      connection = DriverManager.getConnection("jdbc:google:rdbms://instance_name/guestbook")
		      val content = req.getParameter("content")
		      if (content == "")
		      	out.println("<html><head><link type='text/css' rel='stylesheet' href='/stylesheets/main.css' /></head><body>You are missing a message! Try again! Redirecting in 3 seconds...</body></html>")
				else
				{
		      	val statement ="INSERT INTO entries (guestName, content) VALUES( ? , ? )"
		      	val preparedStatement = connection.prepareStatement(statement)
		      	preparedStatement.setString(1, if (req.getUserPrincipal() != null) req.getUserPrincipal().getName() else "anonymous")
		      	preparedStatement.setString(2, content)
		      	var success = 2
		      	success = preparedStatement.executeUpdate()
		      	if (success == 1)
		        		out.println("<html><head><link type='text/css' rel='stylesheet' href='/stylesheets/main.css' /></head><body>Success! Redirecting in 3 seconds...</body></html>")
					else if (success == 0)
		        		out.println("<html><head><link type='text/css' rel='stylesheet' href='/stylesheets/main.css' /></head><body>Failure! Please try again! Redirecting in 3 seconds...</body></html>")
		      }
		   }
			catch
			{
		   	case e:SQLException => e.printStackTrace()
			}
			finally
			{
		      if (connection != null) 
		      	try
						connection.close()
		          catch
					 {
		          	case ignore:SQLException => ()
					 }
		   }
			resp.setHeader("Refresh","3; url=/guestbook.jsp")
	    }
	}

Once again, we need to create a *Connection* object and use a *DriverManager* to help initiate the connection. We then create a prepared statement and place the message contents, along with a user name if the poster was signed in, and update the database with this new entry. The last line sets the header on the response to refresh the browser window 3 seconds after the method completes with the *guestbook.jsp* interface.

Using the Google Cloud Storage API
----------------------------------

The Google Cloud Storage service is very similar to the basic Datastore only with less limits placed due to the higher billing costs for using the service. The Google Cloud Storage service is also currently experimental with GAE, but there are a number of features that are not offered by the other datastore options. These include access control lists, OAuth 2.0 authentication and authorization, the ability to resume upload operations if they're interrupted, and a RESTful API among others. One important fact is that all objects created with the Google Cloud Storage service are immutable. To modify an existing object, you must overwrite it with a new object containing your changes.

Before you can begin using the Google Cloud Storage APIs, you need to activate the Google Cloud Storage service for your app and enable billing. The detailed steps can be found in the prerequisites section of `this document`_. Once you have activated the service, you are ready to start using the Google Cloud Storage APIs.

.. _this document: https://developers.google.com/appengine/docs/java/googlestorage/overview

Creating the User Interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~

As with the other two code examples, the user interface will be created using JSPs. The code looks like this:

::

	<%@ page contentType="text/html;charset=UTF-8" language="java" %>
	<%@ page import="java.util.List" %>
	<%@ page import="com.google.appengine.api.users.User" %>
	<%@ page import="com.google.appengine.api.users.UserService" %>
	<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
	<%@ page import="com.google.appengine.api.files.AppEngineFile" %>
	<%@ page import="com.google.appengine.api.files.FileReadChannel" %>
	<%@ page import="com.google.appengine.api.files.FileService" %>
	<%@ page import="com.google.appengine.api.files.FileServiceFactory" %>
	<%@ page import="com.google.appengine.api.files.FileWriteChannel" %>
	<%@ page import="com.google.appengine.api.files.GSFileOptions.GSFileOptionsBuilder" %>
	<%@ page import="java.net.URL" %>
	<%@ page import="com.google.appengine.api.urlfetch.HTTPRequest" %>
	<%@ page import="com.google.appengine.api.urlfetch.HTTPResponse" %>
	<%@ page import="com.google.appengine.api.urlfetch.HTTPMethod" %>
	<%@ page import="com.google.appengine.api.urlfetch.URLFetchService" %>
	<%@ page import="com.google.appengine.api.urlfetch.URLFetchServiceFactory" %>
	<%@ page import="org.w3c.dom.Document" %>
	<%@ page import="org.w3c.dom.*" %>
	<%@ page import="javax.xml.parsers.DocumentBuilderFactory" %>
	<%@ page import="javax.xml.parsers.DocumentBuilder" %>
	<%@ page import="java.io.BufferedReader"%>
	<%@ page import="java.nio.channels.Channels" %>
	<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

	<html>
	  <head>
	    <link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
	  </head>

	  <body>

	    <%
			String BUCKETNAME = "YOUR_BUCKET_NAME";
	      String guestbookName = request.getParameter("guestbookName");
	      if (guestbookName == null) {
	        guestbookName = "default";
	      }
	      pageContext.setAttribute("guestbookName", guestbookName);

	      UserService userService = UserServiceFactory.getUserService();
	      User user = userService.getCurrentUser();
	      if (user != null) {
	        pageContext.setAttribute("user", user);
	    %>
	        <p>Hello, ${fn:escapeXml(user.nickname)}! (You can <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign out</a>.)</p>
	    <%
	      } else {
	    %>
	        <p>Hello! <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign in</a> to include your name with greetings you post.</p>
	    <%
	      }
	    %>

	    <%

				URL url = new URL("http://" + BUCKETNAME + ".storage.googleapis.com");

				HTTPRequest bucketListRequest = new HTTPRequest(url, HTTPMethod.GET);
				URLFetchService service = URLFetchServiceFactory.getURLFetchService();
				HTTPResponse bucketLisResponse = service.fetch(bucketListRequest);
				String content = new String(bucketLisResponse.getContent(), "UTF-8");

				DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory.newInstance();
				DocumentBuilder docBuilder = docBuilderFactory.newDocumentBuilder();
				Document doc = docBuilder.parse(content);

				// normalize text representation
				doc.getDocumentElement().normalize();
				NodeList listOfEntries = doc.getElementsByTagName("Contents");
				if (listOfEntries.getLength() == 0)
				{
			%>
			<p>Guestbook '${fn:escapeXml(guestbookName)}' has no messages.</p>
			<%
				}
				else
				{
			%>
			<p>Messages in Guestbook '${fn:escapeXml(guestbookName)}'.</p>
			<%
					for (int i=0; i<listOfEntries.getLength(); i++)
					{
						Node entryNode = listOfEntries.item(i);
						if (entryNode.getNodeType() == Node.ELEMENT_NODE)
						{
							Element entryElement = (Element) entryNode;
							String entryMessageKey = entryElement.getElementsByTagName("Key").item(0).getNodeValue().trim();
							String fileName = "/gs/" + BUCKETNAME + "/" + entryMessageKey;
							AppEngineFile readableFile = new AppEngineFile(fileName);
							FileService fileService = FileServiceFactory.getFileService();
							FileReadChannel readChannel = fileService.openReadChannel(readableFile, false);
							BufferedReader reader = new BufferedReader(Channels.newReader(readChannel, "UTF-8"));
							String line = reader.readLine();
							pageContext.setAttribute("greeting_content", line);
			%>
			<blockquote>${fn:escapeXml(greeting_content)}</blockquote>
			<%
						}
					}
				}

	    %>

	    <form action="/sign" method="post">
	      <div><textarea name="content" rows="3" cols="60"></textarea></div>
	      <div><input type="submit" value="Post Greeting" /></div>
	      <input type="hidden" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/>
	    </form>

	    <form action="/guestbook.jsp" method="get">
	      <div><input type="text" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/></div>
	    	<div><input type="submit" value="Switch Guestbook"/></div>
	    </form>

	  </body>
	</html>

There is a lot going on in the interface code, so let's break it down into sections. The first section being discussed is the section we are familiar with from the other code examples:

::

	<%
		  String BUCKETNAME = "YOUR_BUCKET_NAME";
     String guestbookName = request.getParameter("guestbookName");
     if (guestbookName == null) {
       guestbookName = "default";
     }
     pageContext.setAttribute("guestbookName", guestbookName);

     UserService userService = UserServiceFactory.getUserService();
     User user = userService.getCurrentUser();
     if (user != null) {
       pageContext.setAttribute("user", user);
   %>
       <p>Hello, ${fn:escapeXml(user.nickname)}! (You can <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign out</a>.)</p>
   <%
     } else {
   %>
       <p>Hello! <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign in</a> to include your name with greetings you post.</p>
   <%
     }
   %>

This section of the code is merely checking to see if the user is logged in to a Google Account and displaying the appropriate login or logout link. The one addition to this section is the *BUCKETNAME* variable. This variable should be set to the name of the bucket that you created in the prerequisites section of `this document`_.

The next section of the code to examine deals with fetching all of the objects in the bucket specified by the *BUCKETNAME* variable:

::

	URL url = new URL("http://" + BUCKETNAME + ".storage.googleapis.com");
	
	HTTPRequest bucketListRequest = new HTTPRequest(url, HTTPMethod.GET);
	URLFetchService service = URLFetchServiceFactory.getURLFetchService();
	HTTPResponse bucketLisResponse = service.fetch(bucketListRequest);
	String content = new String(bucketLisResponse.getContent(), "UTF-8");

This section of the code is displaying a few different techniques and services. First off, the GAE URL Fetch service APIs are being used to send a GET request to the bucket we are interested in. This process involves creating an *HTTPRequest* object to represent the GET request, creating a *URLFetchService* object to fetch the request's response and an *HTTPResponse* object to store the response for use. The GET request in question is part of the Google Cloud Storage XML RESTful APIs, which are `documented here`_. As GAE support for Google Cloud Storage is still experimental, there is no set Java method to retrieve the contents of a bucket, which is why we have to resort to this method.

.. _documented here: https://developers.google.com/storage/docs/developer-guide

In the next section of the code, we parse the XML response of our GET request:

::

		DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory.newInstance();
		DocumentBuilder docBuilder = docBuilderFactory.newDocumentBuilder();
		Document doc = docBuilder.parse(content);
	
		// normalize text representation
		doc.getDocumentElement().normalize();
		NodeList listOfEntries = doc.getElementsByTagName("Contents");
		if (listOfEntries.getLength() == 0)
		{
	%>
	<p>Guestbook '${fn:escapeXml(guestbookName)}' has no messages.</p>
	<%
		}
		else
		{
	%>
	<p>Messages in Guestbook '${fn:escapeXml(guestbookName)}'.</p>

The first three lines create a *DocumentBuilder* object that we can use to parse the XML response. We then normalize the text representation so that we can query our newly parsed response content by XML tag names. We get the "Contents" tag and check to see if there are any messages stored within this guestbook's bucket.

The next section of the code represents the logic behind extracting all of the messages from the XML response:

::

	<%
			for (int i=0; i<listOfEntries.getLength(); i++)
			{
				Node entryNode = listOfEntries.item(i);
				if (entryNode.getNodeType() == Node.ELEMENT_NODE)
				{
					Element entryElement = (Element) entryNode;
					String entryMessageKey = entryElement.getElementsByTagName("Key").item(0).getNodeValue().trim();
					String fileName = "/gs/" + BUCKETNAME + "/" + entryMessageKey;
					AppEngineFile readableFile = new AppEngineFile(fileName);
					FileService fileService = FileServiceFactory.getFileService();
					FileReadChannel readChannel = fileService.openReadChannel(readableFile, false);
					BufferedReader reader = new BufferedReader(Channels.newReader(readChannel, "UTF-8"));
					String line = reader.readLine();
					pageContext.setAttribute("greeting_content", line);
	%>
	<blockquote>${fn:escapeXml(greeting_content)}</blockquote>
	<%
				}
			}
		}
		
	%>

This section is where we use the Google Cloud Storage Java APIs to access each file within the bucket. We first create the file name using the bucket name and the key retrieved from the XML response. We then create an *AppEngineFile* object to represent the file and a *FileReadChannel* object to represent the read channel. Due to the fact that all messages are stored on a single line, we simply retrieve this line from the reader and display it on the page.

The final section of the code represents the same two forms used in the original datastore code sample.

Creating New Guestbook Entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The sign servlet is where new guestbook entries are created. The code for the sign servlet looks like this:

::

	package guestbook

	import java.util.logging.Logger
	import java.util.Date
	import java.io.PrintWriter
	import java.nio.channels.Channels
	import javax.servlet.http.{HttpServlet, HttpServletRequest => HSReq, HttpServletResponse => HSResp}
	import com.google.appengine.api.users.{User, UserService => UServ, UserServiceFactory => UServFactory}
	import com.google.appengine.api.files.{AppEngineFile, FileReadChannel, FileService, FileServiceFactory, FileWriteChannel}
	import com.google.appengine.api.files.GSFileOptions.GSFileOptionsBuilder

	class SignGuestbookServlet extends HttpServlet
	{
	    val log = Logger.getLogger("SignGuestbookServlet")
		 // You might make this depend on the guest book name for example.
		 val BUCKETNAME = "YOUR_BUCKET_NAME"
		 // You might make this depend on information specific to the message being posted for example.
		 val FILENAME = "YOUR_FILE_NAME"

	    override def doPost( req : HSReq, resp : HSResp)
	    {
	      val userService = UServFactory.getUserService()
	      val user = userService.getCurrentUser()

	      val guestbookName = req.getParameter("guestbookName")
	      val content = req.getParameter("content")
	      val date = new Date()

			val fileService = FileServiceFactory.getFileService()
			val optionsBuilder = new GSFileOptionsBuilder().setBucket(BUCKETNAME).setKey(FILENAME).setAcl("public-read").addUserMetadata("dateCreated", date.toString()).addUserMetadata("author", user.toString())
			val writableFile = fileService.createNewGSFile(optionsBuilder.build())

			// Lock for writing because we intend to finalize this object.
			val lockForWrite = true
			val writeChannel = fileService.openWriteChannel(writableFile, lockForWrite)
			val out = new PrintWriter(Channels.newWriter(writeChannel, "UTF8"))
			out.println(content)
			out.close()

			// Finalize the object so that it can be read from later.
			writeChannel.closeFinally()
			log.info("Just created new entry in guestbook: " + content + "\nfrom user: " + user)

			resp.sendRedirect("/guestbook.jsp?guestbookName=" + guestbookName)
	    }
	}

The first important thing to note involves the two new values added to the servlet, *BUCKETNAME* and *FILENAME*. While these are represented by constant values, you would likely need to change these for different entries. You might for example base your bucket name on the name of the guest book that you are submitting an entry to. You might base the file name on some unique combination of the message's properties, such as the author's name and the date created. Once you have figured this out, all you need to do is use a *GSFileOptionsBuilder* object to configure your new message and then create a new *GSFile* object to represent it. You then open up a channel for writing and lock it for exclusive access since the message is going to be finalized in this process.

As noted earlier, files stored using the Google Cloud Storage services are immutable once saved. Therefore you need to explicitly finalize the object to state that you are done making changes to it. The servlet ends by redirecting back to the guestbook.