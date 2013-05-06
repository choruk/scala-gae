================
Configuring Ant
================

Google provides a lot of information about how to `configure Ant for use with Java`_, but most of this information does not apply if you wish to use Ant with Scala. This section will explain how to configure Ant for use with Scala and will repeat some of the information from the Google docs that still applies for Scala.

.. _configure Ant for use with Java: https://developers.google.com/appengine/docs/java/tools/ant

Initial Configurations
------------------------

The *build.xml* file is used to configure Ant and a new *build.xml* file should be placed in the top level directory of each project you wish to use it for. There are a number of tasks you can accomplish with Ant, but to use it with GAE there are some initial configurations you need to do.

Import the GAE Ant Macros
~~~~~~~~~~~~~~~~~~~~~~~~~

There are a number of GAE Ant macros that allow you to execute GAE commands through Ant. In order to use these macros, you must tell Ant where to look for them, which can be accomplished with the following two lines:

*<property name="sdk.dir" location="../appengine-java-sdk" />*

*<import file="${sdk.dir}/config/user/ant-macros.xml" />*

	**Note:** This assumes that you have placed the GAE Java SDK in the directory which contains your project's top-level directory.

Set the Project CLASSPATH
~~~~~~~~~~~~~~~~~~~~~~~~~

To set the CLASSPATH that Ant will use when executing tasks, you simply need to create a path element with an id of "project.classpath". You typically include any extra JARs that your project needs in the *war/WEB-INF/lib* directory and thus your CLASSPATH will need to include those JARs as well as the GAE SDK JARs.

*<path id="project.classpath">*

  *<pathelement path="${build.dir}" />*
        
    *<fileset dir="${lib.dir}">*

      *<include name="\*\*/\*.jar" />*

    *</fileset>*
        
    *<fileset dir="${sdk.dir}/lib">*

      *<include name="shared/\*\*/\*.jar" />*
        
    *</fileset>*

*</path>*

	**Note:** All of the Ant examples here will use properties defined earlier in the *build.xml* file. Refer to the complete *build.xml* sample files included in the github samples for clarity.

Creating Targets
----------------

If you have worked with Ant before then you already know all about targets. For those that haven't used Ant, targets are, in a nutshell, how you specify the tasks that Ant can execute. You can create them with the *<target name="">* directive and add dependencies so that certain targets are always executed. Then you can execute them at the command line with the format *ant targetName*, where targetName is the name you specify in the *build.xml* file.

The Scala Init Target
~~~~~~~~~~~~~~~~~~~~~

To be able to use Scala commands within Ant, you need an initializer target that will load up all of the Scala commands that Ant can use. In all of the *build.xml* files, this is the target with the name "init". Once this target is created, you can use Scala commands within Ant by making the target that uses the Scala command depend on the "init" target. For clarity, the "init" target is displayed below.

*<target name="init">*

    *<path id="build.classpath">*

        *<pathelement location="${scala-library.jar}" />*

        *<pathelement location="${build.dir}" />*

    *</path>*
    
    *<taskdef resource="scala/tools/ant/antlib.xml">*

        *<classpath>*

            *<pathelement location="${scala-compiler.jar}" />*

            *<pathelement location="${scala-library.jar}" />*

            *<pathelement location="${scala-reflect.jar}" />*

        *</classpath>*

    *</taskdef>*

*</target>*

A Scala Compile Target
~~~~~~~~~~~~~~~~~~~~~~

One target that clearly must depend on "init" is the "compile" target, as it will need to use the *scalac* command in order to compile the *.scala* files. A sample "compile" target might look like the following:

*<target name="compile" depends="copyjars, init" description="Compiles Scala source and copies other source files to the WAR.">*

    *<mkdir dir="${build.dir}" />*
    
    *<copy todir="${build.dir}">*

        *<fileset dir="${src.dir}">*

            *<exclude name="\*\*/\*.scala" />*

        *</fileset>*

    *</copy>*
    
    *<scalac srcdir="${src.dir}" destdir="${build.dir}" classpathref="project.classpath" />*

*</target>*

	**Note:** The "copyjars" target simply copies all of the JARs that GAE will need when executing your application. Refer to the complete *build.xml* sample files included in the github samples for clarity.
	
A Target for Starting the Development Server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here's where those GAE Ant macros that we imported are going to come in handy. A common workflow when developing is to make some changes, ensure that the files all still compile and then finally ensure that they behave as expected when running. You can address this entire workflow with one command at the Terminal prompt using the "runserver" target displayed below, i.e. *ant runserver*. Because it depends on the "compile" target, when you execute the "runserver" target, all actions associated with the "compile" target will be executed first and just like that you can compile all of your Scala code and launch the GAE development server.

*<target name="runserver" depends="compile" description="Starts the development server.">*

    *<dev_appserver war="war" port="8888" />*

*</target>*

Other Targets
~~~~~~~~~~~~~

There are a number of other targets that you can define within the *build.xml* file to facilitate development. Take a look at the complete *build.xml* sample files included in the github samples for more ideas.