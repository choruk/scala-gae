=============
Installation
=============

To be certain that anyone can easily follow along with this documentation, I will first discuss the installation and setup required. Some of this is required to use Google App Engine (GAE), while some of it is required because of the specific design decisions that I made (i.e. using Scala and Ant).

Google App Engine Setup
-----------------------

First, I will discuss the setup required to use the Java implementation of GAE.

1. The most obvious part of this setup process is to ensure that you have the `latest Java Developer Kit (JDK) installed`_. I will be using Java 7 throughout, but you can get away with Java 6 if absolutely necessary.

.. _latest Java Developer Kit (JDK) installed: http://java.sun.com/javase/downloads/index.jsp

2. The next most obvious step is to download the `latest GAE SDK`_. I am using version 1.7.7 of the GAE Java SDK, but there might be a newer one out if you are reading this in the future (hello from the past!). You'll find plenty of information provided by Google if you are having trouble with this step, but once you download the GAE SDK you should have a top level directory of the form "appengine-java-sdk-x.x.x" where "x.x.x" will be the SDK version number. For clarity, just rename this directory to "appengine-java-sdk" as this is how I will refer to it.

.. _latest GAE SDK: https://developers.google.com/appengine/downloads#Google_App_Engine_SDK_for_Java

3. This step introduces the first point where you have multiple options to choose from. To facilitate the development process when working with GAE, a project configuration tool of some sort is needed. For those of you who like using IDEs, Eclipse has incredible support for GAE (see `Google Plugin for Eclipse`_). I chose to go a different route and use a command line configuration tool called `Apache Ant`_. You can find some information about how to install Ant on their website, but I will discuss this in some detail later_ as well.

.. _Google Plugin for Eclipse: https://developers.google.com/appengine/docs/java/tools/eclipse
.. _Apache Ant: https://ant.apache.org

Scala Setup
-----------

As Scala will be used for much of the programming throughout this documentation, you will of course need to setup Scala. For all of you OS X users out there, this setup should be hilariously easy. Go get Homebrew_ if you don't have it yet and then simply type *brew install scala* at a Terminal prompt to get the latest stable release. As of this writing, the latest stable release is version 2.10.1, which is what I will be using.

For those of you not using OS X (what are you doing with your life?), you can get the latest stable release of Scala here_.

.. _Homebrew: http://mxcl.github.io/homebrew/
.. _here: http://www.scala-lang.org/downloads

Ant Setup
---------

.. _later:

Apache Ant is a really useful command line tool that allows you to accomplish the repetitive tasks involved with developing and deploying quickly and efficiently.

1. To use Apache Ant you must have a Java environment installed, but you need this for GAE as well so you should already have it, right?

2. Next, `download one of the ant binaries`_ and uncompress the file into a folder where you wish Ant to reside.

.. _download one of the ant binaries: https://ant.apache.org/bindownload.cgi

3. Once you have found a home for Ant, you need to set an environment variable called ANT_HOME to the directory where Ant resides. You should also have an environment variable called JAVA_HOME and SCALA_HOME at this point as well.
	
	**Note:** If you are using OS X, there is a very easy way to set these environment variables that requires administrator privileges. You can set them all in the file */etc/launchd.conf* in the form "setenv ANT_HOME /path/to/apache-ant-x.x.x" on separate lines. After saving this file, simply enter *grep -E "^setenv" /etc/launchd.conf | xargs -t -L 1 launchctl* at the Terminal prompt and restart the Terminal app. Now when you enter the command *export* with no options, you should see your new environment variables listed among others.

4. Finally, you need to add the Ant bin to your PATH.

	**Note:** On OS X, this can be done by adding "${ANT_HOME}/bin" to the */etc/paths* file.

If you are successful, *ant -version* should return the version of Ant that you have installed. I am using version 1.9.0 because this version is the most recent stable release as of this writing.