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