Set shell = CreateObject("WScript.Shell")
folder = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
launcher = folder & "run_calculator.cmd"
shell.Run """" & launcher & """", 1, False
