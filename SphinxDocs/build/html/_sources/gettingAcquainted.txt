==========================================
Getting Acquainted With Google App Engine
==========================================

Before you begin developing and deploying apps to GAE, there are a few pieces of information that are vital to your success. 

Expected Directory Structure
-----------------------------

When deploying your app to GAE, your compiled classes and other resources must be placed within a specific file structure to be properly served by GAE. GAE uses the WAR format, such that any file within the *war* directory in your apps top level directory is considered part of the complete app. A snapshot of the *war* directory might look like the following:

::

  war/                          
    WEB-INF/                   
      lib/                    
      classes/                

Inside of the *war* directory, but outside of the *WEB-INF* directory, you would place any static resources such as image files, as well as any interfaces for your app such as JSP files. Just inside the *WEB-INF* directory, you would place any app configuration files such as the *web.xml* or *appengine-web.xml* files. The *lib* directory is meant to contain the class files of any classes that your app needs while executing, while the *classes* directory contains the class files for your app's classes.

The Deployment Descriptor (*web.xml*)
--------------------------------------

To specify your apps routes, require authentication for specific pages, and other web page configuration, you use the *web.xml* file. Every GAE app needs a deployment descriptor as this file is where you map your servlets, JSPs and other files to actual URLs. For a complete description of this file, see the `Google Developer docs`_.

.. _Google Developer docs: https://developers.google.com/appengine/docs/java/config/webxml

The App Config Descriptor (*appengine-web.xml*)
------------------------------------------------

For further configurations within your app and to declare your app's registered app ID and version number, you use the *appengine-web.xml* file. One important element to set within this file is the *<threadsafe>* element. By writing *<threadsafe>true</threadsafe>* in your *appengine-web.xml* file, you are specifying that GAE can use concurrent requests while executing your app. You can also handle configuration such as declaring what files are static (images, CSS, etc.) and what files are resources (JSPs, etc.), configure cache expiration times for static files and much more. For a complete description of this file, see `Google's documentation`_.

.. _Google's documentation: https://developers.google.com/appengine/docs/java/config/appconfig

Configure Logging Behavior
--------------------------

All GAE logging is through java.util.logging by default. To configure the logging behavior of your app, you must add the following lines to your *appengine-web.xml* file:

::

   <system-properties>
      <property name="java.util.logging.config.file" value="WEB-INF/logging.properties"/>
   </system-properties>

These lines tell GAE to look in the *war/WEB-INF* directory for a file named *logging.properties* for logging configurations. Inside of this *logging.properties* file you can specify different logging levels:

- FINEST (lowest level)
- FINER
- FINE
- CONFIG
- INFO
- WARNING
- SEVERE (highest level)

A simple *logging.properties* file might look like this:

::

	# Set the default logging level for all loggers to WARNING
	.level = WARNING
	# Specifically set the logging level for the guestbook package to INFO
	guestbook.level = INFO

