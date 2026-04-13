@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "JMETER_EXE=C:\Users\Usuario\Documents\apache-jmeter-5.6.3\bin\jmeter.bat"

if not exist "%JMETER_EXE%" (
	set "JMETER_EXE=jmeter"
)

echo Running BlazeDemo Spike Test...
if exist "%SCRIPT_DIR%results\spike_test_results.jtl" (
	del /q "%SCRIPT_DIR%results\spike_test_results.jtl"
)
if exist "%SCRIPT_DIR%results\spike_report" (
	rmdir /s /q "%SCRIPT_DIR%results\spike_report"
)
call "%JMETER_EXE%" -n -t "%SCRIPT_DIR%jmeter\blazedemo_spike_test.jmx" -l "%SCRIPT_DIR%results\spike_test_results.jtl" -e -o "%SCRIPT_DIR%results\spike_report"

if errorlevel 1 (
	echo.
	echo ERROR: Could not run JMeter. Check if JMeter is installed and available in PATH.
	echo If needed, edit this file and set JMETER_EXE to your jmeter.bat full path.
	pause
	exit /b 1
)

echo.
echo Spike test finished. Open: "%SCRIPT_DIR%results\spike_report\index.html"
pause