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