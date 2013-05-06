package helloworld

import javax.servlet.http.{HttpServlet, HttpServletRequest => HSReq, HttpServletResponse => HSResp}
import com.google.appengine.api.users.{User, UserService => UServ, UserServiceFactory => USF}

class HelloWorldServlet extends HttpServlet
{
    override def doGet(req : HSReq, resp : HSResp) =
    {
        val userService = USF.getUserService()
        val user = userService.getCurrentUser()

        if (user != null)
        {
            resp.setContentType("text/plain")
            resp.getWriter().println("Hello, " + user.getNickname() + ", from Scala")
        }
        else
            resp.sendRedirect(userService.createLoginURL(req.getRequestURI()))
    }
}