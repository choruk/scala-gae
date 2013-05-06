==============
Hello, Scala!
==============

Now that you have completed the necessary installations and other setup tasks, you are ready to start coding! This first code example is the obligatory Hello, World! program with a small addition. This addition involves using the Google Users service to allow visitors to sign in with a Google account.

In this code example, you will learn how to:

- Write a simple servlet in Scala to display a webpage.

- Map a Scala servlet to a URL for use by Google App Engine.

- Use the Google Users service to allow users to sign in with a Google account.

The Configuration Code
----------------------

First things first, let's set up the deployment descriptor and app config descriptor files so that we can test our app as we go. The deployment descriptor should look like this:

::

	<web-app xmlns="http://java.sun.com/xml/ns/javaee" version="2.5">
	    <servlet>
	        <servlet-name>helloworld</servlet-name>
	        <servlet-class>helloworld.HelloWorldServlet</servlet-class>
	    </servlet>
	    <servlet-mapping>
	        <servlet-name>helloworld</servlet-name>
	        <url-pattern>/helloworld</url-pattern>
	    </servlet-mapping>
	    <welcome-file-list>
	        <welcome-file>helloworld</welcome-file>
	    </welcome-file-list>
	</web-app>

This code maps the servlet class *helloworld.HelloWorldServlet* to the servlet name *helloworld* and subsequently maps that servlet name to the */helloworld* URL. Similarly, by placing the servlet's name in the welcome file list, the servlet will be mapped to the root URL as well.

The other file we need is the app config descriptor, which should look like this:

::

	<?xml version="1.0" encoding="utf-8"?>
	<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
	    <application></application>
	    <version>1</version>
	    <threadsafe>true</threadsafe>
	</appengine-web-app>
	
**Note:** The *<application>* tag is used to inform GAE of the app's registered ID. Since this app will only be used for testing purposes, it will not have an app ID.

The Servlet Code
----------------

First things first, let's write a simple Scala servlet that will display a webpage with some static content. Create a *HelloWorldServlet.scala* file and add the following code:

::

	package helloworld
	
	import javax.servlet.http.{HttpServlet, HttpServletRequest => HSReq, HttpServletResponse => HSResp}
	
	class HelloWorldServlet extends HttpServlet
	{
	    override def doGet(req : HSReq, resp : HSResp) =
	    {
	    	resp.setContentType("text/plain")
	    	resp.getWriter().println("Hello World, from Scala")
	    }
	}

This simple servlet will display a webpage with the text "Hello World, from Scala" on it. Deploy your app to the development server and load up the app in your web browser to confirm.

Now for the addition. The Google Users service API provides an interface to allow users to sign in with a Google account, as well as for developers to interact with the current user. The following import statement is needed to use the Google Users service:

::

	import com.google.appengine.api.users.{User, UserService => UServ, UserServiceFactory => UServFactory}

Once you have added this import statement to your *HelloWorldServlet.scala* file, change the *doGet* method to look like the following:

::

	override def doGet(req : HSReq, resp : HSResp) =
    {
        val userService = UServFactory.getUserService()
        val user = userService.getCurrentUser()

        if (user != null)
        {
            resp.setContentType("text/plain")
            resp.getWriter().println("Hello, " + user.getNickname() + ", from Scala")
        }
        else
            resp.sendRedirect(userService.createLoginURL(req.getRequestURI()))
    }

Now, when someone visits the hello world app's webpage, they will either be prompted to sign in to a Google account or a welcome message will be displayed, tailored to their Google account's nickname.

	**Note:** On the development server, the Google Users service simulates the expected behavior by simply allowing you to sign in with any email address you wish without having to enter a password. This allows you to easily test your app when developing.
