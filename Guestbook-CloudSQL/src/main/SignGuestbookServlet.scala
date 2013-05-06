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