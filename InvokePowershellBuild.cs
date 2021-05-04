using System;
using System.Threading;
using System.Management.Automation;

using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

public class InvokePowershellBuild : Task, ICancelableTask
{
    [Required] public string BuildEntryPs1 { get; set; }
    [Required] public string SolutionRoot { get; set; }
    [Required] public string SdkInstallPath { get; set; }
    [Required] public string GameInstallPath { get; set; }
    [Required] public string BuildEntryConfig { get; set; }

    private PowerShell _ps;

    private ManualResetEventSlim _startingMre = new ManualResetEventSlim(false);

    public override bool Execute()
    {
        bool isSuccess = false;

        try
        {
            _ps = PowerShell.Create();

            _ps
                .AddCommand("Set-ExecutionPolicy")
                .AddArgument("Unrestricted")
                .AddParameter("Scope","CurrentUser");
            
            _ps
                .AddStatement()
                .AddCommand(BuildEntryPs1)
                .AddParameter("srcDirectory", SolutionRoot)
                .AddParameter("sdkPath", SdkInstallPath)
                .AddParameter("gamePath", GameInstallPath)
                .AddParameter("config", BuildEntryConfig);

            BindStreamEntryCallback(_ps.Streams.Debug, record => Log.LogMessage(MessageImportance.High, record.ToString()));
            BindStreamEntryCallback(_ps.Streams.Information, record => Log.LogMessage(MessageImportance.High, record.ToString()));
            BindStreamEntryCallback(_ps.Streams.Verbose, record => Log.LogMessage(MessageImportance.High, record.ToString()));
            BindStreamEntryCallback(_ps.Streams.Warning, record => Log.LogMessage(MessageImportance.High, record.ToString())); // TODO: More flashy output?

            BindStreamEntryCallback(_ps.Streams.Error, record =>
            {
                // TODO: Less info than when from console
                // TODO: More flashy output?
                Log.LogMessage(MessageImportance.High, record.ToString());
                // Log.LogMessage(MessageImportance.High, "PREVIOUS IS ERR");
                isSuccess = false;
            });

            _ps.InvocationStateChanged += (sender, args) => 
            {
                if (args.InvocationStateInfo.State == PSInvocationState.Running)
                {
                    _startingMre.Set();
                }
            };

            isSuccess = true;
            _ps.Invoke();
        }
        catch (System.Exception e)
        {
            Log.LogError(e.Message);
            isSuccess = false;
        }

        return isSuccess;
    }

    public void Cancel()
    {
        // Log.LogMessage(MessageImportance.High, "Got cancel");

        // Do not call Stop() until we know that we've actually started
        // This could be more elaborate, but the time interval between Execute() and Invoke() being called is extremely small

        _startingMre.Wait();
        _ps.Stop();
    }

    private static void BindStreamEntryCallback<T>(PSDataCollection<T> stream, Action<T> handler)
    {
        stream.DataAdded += (object sender, DataAddedEventArgs e) => handler(stream[e.Index]);
    }
}