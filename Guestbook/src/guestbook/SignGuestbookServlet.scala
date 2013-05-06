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