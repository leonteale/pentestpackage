@echo off

::set CMD window size
mode con: cols=70 lines=50

:: Set global variables - change as required
set powermenu_directory="%userprofile%\powermenu"

::start menu
:MENU

CLS 

ECHO ============= Powershell Menu - @LeonTeale =============
	setlocal EnableDelayedExpansion
		    IF EXIST %powermenu_directory% (
		    ECHO Available Tools:
		   	dir /a:d /b
			)
ECHO --------------------------------------------------------
ECHO 1. Run powershell as a Local user
ECHO 2. Run powershell as a remote user
ECHO 3. Load this script as authenticated user
ECHO 4. Selection 4 
ECHO 5. Selection 5 
ECHO 6. Selection 6 
ECHO 7. Selection 7 
ECHO -------------------------------------------------------- 
ECHO Powershell Recon
ECHO --------------------------------------------------------
ECHO 8. Get Domain name
ECHO 9. Export Domain Users
ECHO --------------------------------------------------------
ECHO Config: 
ECHO --------------------------------------------------------
		
ECHO 10. Set powersploit location
ECHO 11. Download powersploit
ECHO 12. Download Inveigh
ECHO 13. Set Inveigh location
ECHO --------------------------------------------------------
ECHO ===================PRESS 'Q' TO QUIT==================== 
ECHO. 


:: Coming Soon
::
:: UAC bypass - 'UACME'
:: Custom Priv esc checks
:: Inveigh (powershell responder




SET INPUT= 
SET /P INPUT=Please select a number: 
IF /I '%INPUT%'=='1' GOTO Selection1 
IF /I '%INPUT%'=='2' GOTO Selection2 
IF /I '%INPUT%'=='3' GOTO Selection3 
IF /I '%INPUT%'=='4' GOTO Selection4 
IF /I '%INPUT%'=='5' GOTO Selection5 
IF /I '%INPUT%'=='6' GOTO Selection6 
IF /I '%INPUT%'=='7' GOTO Selection7 
IF /I '%INPUT%'=='8' GOTO Selection8 
IF /I '%INPUT%'=='9' GOTO Selection9 
IF /I '%INPUT%'=='10' GOTO Selection10 
IF /I '%INPUT%'=='11' GOTO Selection11
IF /I '%INPUT%'=='12' GOTO Selection12
IF /I '%INPUT%'=='13' GOTO Selection13
IF /I '%INPUT%'=='Q' GOTO Quit 

CLS 

ECHO ============INVALID INPUT============ 
ECHO ------------------------------------- 
ECHO Please select a number from the Main 
echo Menu [1-9] or select 'Q' to quit. 
ECHO ------------------------------------- 
ECHO ======PRESS ANY KEY TO CONTINUE====== 

PAUSE > NUL 
GOTO MENU 

:Selection1 


:: UAC eleviate privs
::-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )

::--------------------------------------
start c:\windows\system32\cmd.exe /k powershell


PAUSE > NUL
GOTO MENU

:Selection2 

set /p domain="Enter Domain: "
set /p user="Enter User: "
runas /netonly /user:%domain%\%user% "c:\windows\system32\cmd.exe /k powershell"


PAUSE > NUL
GOTO MENU

:Selection3

set /p domain="Enter Domain: "
set /p user="Enter User: "
runas /netonly /user:%domain%\%user% "%powermenu_directory%\powermenu.bat "

EXIT

:Selection4 and so on 

:Selection5 and so on 

:Selection6 and so on 

:Selection7 and so on 

:Selection8 

ECHO Run the following within powersploit: 'Import-Module PowerSploit.psm1; Get-NetDomain'
ECHO.
set /p autorun="Would you like to autorun this shell script? (y/n)"

setlocal EnableDelayedExpansion

if "%autorun%"=="y" (
	if EXIST %powermenu_directory%\PowerSploit-master  (
							
				    	  	start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "import-module %powermenu_directory%\PowerSploit-master\PowerSploit.psm1;Get-NetDomain;Read-Host -Prompt 'Press Enter to continue'"
		    	  			) else (
		    	  					echo "powersploit location not set. Please set this within the Menu")
									PAUSE > NUL
									GOTO MENU
		) else (
				ECHO "Press enter to continue.."
				PAUSE > NUL
				GOTO MENU
)





PAUSE > NUL
GOTO MENU

:Selection9 


ECHO Run the following within powersploit: 
ECHO 'Import-Module PowerSploit.psm1; Get-NetUser'
ECHO.
ECho Make sure you are running as a domain authenticated user
ECHO.
set /p autorun="Would you like to autorun this shell script? (y/n)"

setlocal EnableDelayedExpansion

if "%autorun%"=="y" (
	if EXIST %powermenu_directory%\PowerSploit-master  (
							
				    	  	start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "import-module%powermenu_directory%\PowerSploit-master\PowerSploit.psm1;Get-NetUser;Read-Host -Prompt 'Press Enter to continue'"
		    	  			) else (
		    	  					echo "powersploit location not set. Please set this within the Menu")
									PAUSE > NUL
									GOTO MENU
		) else (
				ECHO "Press enter to continue.."
				PAUSE > NUL
				GOTO MENU
)


PAUSE > NUL
GOTO MENU


:Selection10

  rem       set /p powersploit_loc="Where is powersploit folder located: "
  rem       echo %powersploit_loc%> %userprofile%\powermenu.conf
  rem       ECHO.
		rem ECHO "Location set....Press enter to return to menu"
		rem PAUSE > NUL
		rem GOTO MENU


PAUSE > NUL
GOTO MENU

:Selection11


start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "(New-Object Net.WebClient).DownloadFile('https://codeload.github.com/PowerShellMafia/PowerSploit/zip/master', 'powersploit.zip')"
start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "echo 'downloading PowerSploit from Github'; Invoke-WebRequest https://codeload.github.com/PowerShellMafia/PowerSploit/zip/master -OutFile %powermenu_directory%\powersploit.zip"

        ECHO Powersploit downloaded to "%powermenu_directory%\powersploit.zip"
		PAUSE > NUL
		GOTO MENU

:Selection12

start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "(New-Object Net.WebClient).DownloadFile('https://codeload.github.com/Kevin-Robertson/Inveigh/zip/master', 'Inveigh.zip')"
start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "echo 'downloading PowerSploit from Github'; Invoke-WebRequest https://codeload.github.com/Kevin-Robertson/Inveigh/zip/master -OutFile %powermenu_directory%\Inveigh.zip"

        ECHO Powersploit downloaded to "%powermenu_directory%\Inveigh.zip"
		PAUSE > NUL
		GOTO MENU


:Selection13


ECHO Run the following within powersploit: 
ECHO 'Import-Module Inveigh.psm1; XXXXX'
ECHO.
ECho Make sure you are running as a domain authenticated user
ECHO.
set /p autorun="Would you like to autorun this shell script? (y/n)"

setlocal EnableDelayedExpansion

if "%autorun%"=="y" (
	if EXIST %powermenu_directory%\PowerSploit-master  (
							
				    	  	start C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -Command "import-module %powersploit_loc%\PowerSploit.psm1;Get-NetUser;Read-Host -Prompt 'Press Enter to continue'"
		    	  			) else (
		    	  					echo "powersploit location not set. Please set this within the Menu")
									PAUSE > NUL
									GOTO MENU
		) else (
				ECHO "Press enter to continue.."
				PAUSE > NUL
				GOTO MENU
)


PAUSE > NUL
GOTO MENU



PAUSE > NUL
GOTO MENU

:Quit 
CLS 

ECHO ==============THANKYOU=============== 
ECHO.
ECHO ======PRESS ANY KEY TO CONTINUE====== 

PAUSE>NUL 
EXIT