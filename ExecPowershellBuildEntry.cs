using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Diagnostics;
using System.IO;

public class ExecPowershellBuildEntry : Task, ICancelableTask
{
    private Process _process;
    private object _startLock = new object();

    [Required] public string BuildEntryPs1 { get; set; }
    [Required] public string SolutionRoot { get; set; }
    [Required] public string SdkInstallPath { get; set; }
    [Required] public string GameInstallPath { get; set; }
    [Required] public string BuildEntryConfig { get; set; }

    public override bool Execute()
    {
        // TODO

        // Log.LogMessage(BuildEntryPs1);
        // Log.LogMessage(Path.GetFullPath(BuildEntryPs1));

        // Log.LogMessage(SolutionRoot);
        // Log.LogMessage(Path.GetFullPath(SolutionRoot));
        
        bool isSuccess = false;

        try
        {
            // lock (_startLock)
            {
                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = "C:\\Windows\\System32\\PING.EXE";
                // startInfo.FileName = "C:\\Windows\\System32\\robocopy.EXE";
                startInfo.Arguments = "127.0.0.1";
                startInfo.RedirectStandardInput = true;
                startInfo.RedirectStandardOutput = true;
                startInfo.RedirectStandardError = true;
                startInfo.UseShellExecute = false;
                startInfo.CreateNoWindow = true;

                _process = new Process();
                _process.StartInfo = startInfo;
                _process.OutputDataReceived += (sender, e) => {
                    if (e.Data == null) return;
                    Log.LogMessage(MessageImportance.High, e.Data);
                };
                _process.ErrorDataReceived += (sender, e) => {
                    if (e.Data == null) return;
                    Log.LogMessage(MessageImportance.High, e.Data); // TODO
                };
                _process.Start();

                _process.BeginOutputReadLine();
                _process.BeginErrorReadLine();
            }

            _process.WaitForExit();

            isSuccess = _process.ExitCode == 0;
        }
        catch (System.Exception e)
        {
            Log.LogError(e.Message);
        }

        // Log.LogMessage(SDKInstallPath);
        // Log.LogMessage(GameInstallPath);
        // Log.LogMessage(BuildEntryConfig);
        
        return isSuccess;
    }

    public void Cancel()
    {
        Log.LogMessage(MessageImportance.High, "Got cancel");
        lock (_startLock)
        {
            // https://stackoverflow.com/a/283357/2588539
            // TODO: Doesn't work for ping
            _process.StandardInput.WriteLine("\x3");
        }
    }
}