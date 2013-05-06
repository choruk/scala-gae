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