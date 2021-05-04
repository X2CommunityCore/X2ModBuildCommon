using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Management.Automation;
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

    // public override bool Execute()
    // {
    //     // TODO

    //     // Log.LogMessage(BuildEntryPs1);
    //     // Log.LogMessage(Path.GetFullPath(BuildEntryPs1));

    //     // Log.LogMessage(SolutionRoot);
    //     // Log.LogMessage(Path.GetFullPath(SolutionRoot));
        
    //     bool isSuccess = false;

    //     try
    //     {
    //         // lock (_startLock)
    //         {
    //             ProcessStartInfo startInfo = new ProcessStartInfo();
    //             startInfo.FileName = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe";
    //             // startInfo.FileName = "C:\\Windows\\System32\\PING.EXE";
    //             // startInfo.FileName = "C:\\Windows\\System32\\robocopy.EXE";
    //             // startInfo.Arguments = "127.0.0.1";
    //             startInfo.Arguments = string.Format("–NonInteractive –ExecutionPolicy Unrestricted -file \"{0}\"", BuildEntryPs1);
    //             startInfo.RedirectStandardInput = true;
    //             startInfo.RedirectStandardOutput = true;
    //             startInfo.RedirectStandardError = true;
    //             startInfo.UseShellExecute = false;
    //             startInfo.CreateNoWindow = true;

    //             _process = new Process();
    //             _process.StartInfo = startInfo;
    //             _process.OutputDataReceived += (sender, e) => {
    //                 if (e.Data == null) return;
    //                 Log.LogMessage(MessageImportance.High, e.Data);
    //             };
    //             _process.ErrorDataReceived += (sender, e) => {
    //                 if (e.Data == null) return;
    //                 Log.LogMessage(MessageImportance.High, e.Data); // TODO
    //             };
    //             _process.Start();

    //             _process.BeginOutputReadLine();
    //             _process.BeginErrorReadLine();
    //         }

    //         _process.WaitForExit();

    //         isSuccess = _process.ExitCode == 0;
    //     }
    //     catch (System.Exception e)
    //     {
    //         Log.LogError(e.Message);
    //     }

    //     // Log.LogMessage(SDKInstallPath);
    //     // Log.LogMessage(GameInstallPath);
    //     // Log.LogMessage(BuildEntryConfig);
        
    //     return isSuccess;
    // }

    // public void Cancel()
    // {
    //     Log.LogMessage(MessageImportance.High, "Got cancel");
    //     lock (_startLock)
    //     {
    //         // https://stackoverflow.com/a/283357/2588539
    //         // TODO: Doesn't work for ping
    //         _process.StandardInput.WriteLine("\x3");
    //         _process.StandardInput.Close();
    //     }
    // }

    private PowerShell _ps;

    public override bool Execute()
    {
        // var result = Powershell.Create(BuildEntryPs1).Invoke();

        // foreach (string str in PowerShell.Create().
        //     AddScript("Get-Process").
        //     AddCommand("Out-String").Invoke<string>())
        // {
        //     Log.LogMessage(MessageImportance.High, str);
        // }

        _ps = PowerShell.Create();

        _ps.AddCommand("Set-ExecutionPolicy").AddArgument("Unrestricted");
        _ps.AddStatement().AddCommand(BuildEntryPs1);

        if (_ps.Streams.Debug != null) 
        {
            _ps.Streams.Debug.DataAdded += (object sender, DataAddedEventArgs e) => 
            {
                DebugRecord newRecord = ((PSDataCollection<DebugRecord>)sender)[e.Index];
                Log.LogMessage(MessageImportance.High, newRecord.Message);
            };
        }
        else
        {
            Log.LogMessage(MessageImportance.High, "Debug is null");
        }

        if (_ps.Streams.Information != null) 
        {
            _ps.Streams.Information.DataAdded += (object sender, DataAddedEventArgs e) => 
            {
                InformationRecord newRecord = ((PSDataCollection<InformationRecord>)sender)[e.Index];
                Log.LogMessage(MessageImportance.High, newRecord.MessageData.ToString());
            };
        }
        else
        {
            Log.LogMessage(MessageImportance.High, "Information is null");
        }

        // foreach (string str in ps.Invoke<string>())
        // {
        //     Log.LogMessage(MessageImportance.High, str);
        // }

        _ps.Invoke();

        return true;
    }

    public void Cancel()
    {
        Log.LogMessage(MessageImportance.High, "Got cancel");
        _ps.Stop();
    }
}