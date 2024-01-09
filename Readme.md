#FMX-GRID
Welcome to this new release of the the A-dato FMX-Grid component.

##Features
FMX-Grid provides the following features:
*Available on all platforms
*Connects to different data sources (Lists, ObjectModel, datatset's)
*Smart row caching results in low memory usage
*Fast scrolling

##License
This software is provided as shareware with full source code. The sofware can be used as is and may used to build (commercial) applications.

A commercial license is required when:
*You are distributing applications containing our code
*When you want support

##Installation
Full source code is available from: https://github.com/a-dato/FMX-GRID.git

##Demos

A-Dato Scheduler is the next step in resource scheduling components.
Using our suite makes building scheduling applications easy.


IMPORTANT NOTE
**************

Each version of Delphi supports different properties. It can therefore happen that
when running or opening a file from the Lynx demo application an exception is
raised saying that a certain property cannot be read because this property does
not exist.

To overcome this problem, open each file in your development environment,
apply a small change to the form (for example: update the position of a component)
and save your changes. This will remove any conflicting property from the source code.


****************

Read Release.txt to get information about the latest changes made to this release.

=====================
CONTENTS
=====================
- Installation
- Running and compiling Lynx
- New features
- Demo application

=====================
INSTALLATION
=====================

We advise you to run the installation program as administrator.

The default installation directory has been set to: c:\program files\A-Dato\.

A-Dato Scheduler bpl files are split into runtime- and designtime packages:

  DotNet4Delphi_XX  with DotNet4Delphi_XX_dsgn
  ADato_GridControl_XX with ADato_GridControl_XX_dsgn
  ADato_Controls_XX with ADato_Controls_XX_dsgn
  ADato_Professional_XX with ADato_Professional_XX_dsgn

(XX stands for the Delphi version you are using: Delphi 2010 or Delphi XE)

To actualy install the A-Dato Scheduler components, you need copy the Bpl files
to a directory available on your search path (for example <delphi dir>\projects\Bpl).

For a Delphi installation the Bpl files are located in <installdir>\Bpl. These file
should be copied to your Bpl directory:

  DotNet4Delphi_XX.bpl
  DotNet4Delphi_XX_dsgn.bpl
  ADato_GridControl_XX.bpl
  ADato_GridControl_XX_dsgn.bpl
  ADato_Controls_XX.bpl
  ADato_Controls_XX_dsgn.bpl
  ADato_Professional_XX.bpl
  ADato_Professional_XX_dsgn.bpl

(XX indicates the Delphi version: 2010)

For a C++ Builder installation these file should be copied to this directory:

  DotNet4Delphi_XX.bpl
  DotNet4Delphi_XX_dsgn.bpl
  ADato_GridControl_XX.bpl
  ADato_GridControl_XX_dsgn.bpl
  ADato_Controls_XX.bpl
  ADato_Controls_XX_dsgn.bpl
  ADato_Professional_XX.bpl
  ADato_Professional_XX_dsgn.bpl

And to your Lib directory (<bcb dir>\projects\Lib):

  DotNet4Delphi_XX.bpi
  DotNet4Delphi_XX_dsgn.bpi
  ADato_GridControl_XX.bpi
  ADato_GridControl_XX_dsgn.bpi
  ADato_Controls_XX.bpi
  ADato_Controls_XX_dsgn.bpi
  ADato_Professional_XX.bpi
  ADato_Professional_XX_dsgn.bpi

  DotNet4Delphi_XX.lib
  DotNet4Delphi_XX_dsgn.lib
  ADato_GridControl_XX.lib
  ADato_GridControl_XX_dsgn.lib
  ADato_Controls_XX.lib
  ADato_Controls_XX_dsgn.lib
  ADato_Professional_XX.lib
  ADato_Professional_XX_dsgn.lib

(XX indicates the C++ Builder version: CB2010)

After copying the files, you can install the A-Dato Scheduler components
using the Component|Install package command. You only have to install
the design time packages, being:

  DotNet4Delphi_XX_dsgn.bpl
  ADato_GridControl_XX_dsgn.bpl
  ADato_Controls_XX_dsgn.bpl
  ADato_Professional_XX_dsgn.bpl

(XX indicates the Delphi or C++ Builder version: CB2010)

***********************************
Special note on Vista installations
***********************************

On Vista the directory in which bpl files should be placed has changed.
By default, bpl's should now be copied to:
	C:\Users\Public\Documents\RAD Studio\7.0\BPL

lib files to:
	C:\Users\Public\Documents\RAD Studio\7.0\DCP

In addition, <install dir>Lib\Obj should be added to your
'project's default path' when installing under C++ Builder.

===========================
Running and compiling Lynx 
==========================

Included with this installation are the sources for the Lynx application. These files are installed
in a subdirectory called Demos\Lynx. 

Two versions of Lynx are available:
- Lynx Desktop (project file Demos\Lynx\Desktop\Lynx_2010.dproj)
- Lynx Online (project file Demos\Lynx\LynxOnline\LynxOnline_2010.dproj)

Both versions handle data access through an interface called IDataAccessInterface (DataAccess_intf.pas). 

In the desktop version of Lynx this interface is implemented by class TDesktopDatamodule (Desktop_Datamodule.pas) 
which provides a direct database connection. Through this module, you can connect to a local data base 
file (like the provided Lynx.mdb file) or to a remote SQL server.

Lynx Online connects to our remote Lynx service. IDataAccessInterface is therefore implemented by class TRemoteData 
which provides a gateway to our remote Lynx service. Data communication is handled by the RemObjects SDK, it's 
therefore required to install the RemObjects components prior to compiling Lynx Online.

To test drive Lynx Online, you can download a compiled version of this application using this link:

    http://www.a-dato.net/Portals/0/Downloads/Lynx/Lynx.application


===============================
Other file in this distribution
===============================

In addition to package DotNet4Delphi and A-Dato Scheduler you should also
download and install the Lynx application.

Important:
  It is normally a good idea (especially with C++ builder versions) to copy the
  *.bpl files to a directory located in your search path before installing them
  with 'Component | Install packages'.

The compiled units accompanying these two packages are also located in the
<install dir>\lib directory and it is necessary that you either copy
these files to a directory pointed to by Delphi's library search path or you
should update the search path to include the <install dir>\lib directory.

=====================
NEW FEATURES
=====================

Please read the file Release.txt to see the updates for the
current release.


*******************         End of readme file               *******************
================================================================================
