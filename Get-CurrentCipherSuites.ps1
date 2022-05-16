Try {
  # http://stackoverflow.com/questions/19695623/how-to-call-schannel-functions-from-net-c
  if (-not ([System.Management.Automation.PSTypeName]'ConsoleApplication4').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
namespace ConsoleApplication4
{
    public class Program
    {
        [DllImport("Bcrypt.dll", CharSet = CharSet.Unicode)]
        static extern uint BCryptEnumContextFunctions(uint dwTable, string pszContext, uint dwInterface, ref uint pcbBuffer, ref IntPtr ppBuffer);
        [DllImport("Bcrypt.dll")]
        static extern void BCryptFreeBuffer(IntPtr pvBuffer);
        [DllImport("Bcrypt.dll", CharSet = CharSet.Unicode)]
        static extern uint BCryptAddContextFunction(uint dwTable, string pszContext, uint dwInterface, string pszFunction, uint dwPosition);
        [DllImport("Bcrypt.dll", CharSet = CharSet.Unicode)]
        static extern uint BCryptRemoveContextFunction(uint dwTable, string pszContext, uint dwInterface, string pszFunction);
        [StructLayout(LayoutKind.Sequential)]
        public struct CRYPT_CONTEXT_FUNCTIONS
        {
            public uint cFunctions;
            public IntPtr rgpszFunctions;
        }
        public const uint CRYPT_LOCAL = 0x00000001;
        public const uint NCRYPT_SCHANNEL_INTERFACE = 0x00010002;
        public const uint CRYPT_PRIORITY_TOP = 0x00000000;
        public const uint CRYPT_PRIORITY_BOTTOM = 0xFFFFFFFF;
        public static void DoEnumCiphers()
        {
            uint cbBuffer = 0;
            IntPtr ppBuffer = IntPtr.Zero;
            uint Status = BCryptEnumContextFunctions(
                    CRYPT_LOCAL,
                    "SSL",
                    NCRYPT_SCHANNEL_INTERFACE,
                    ref cbBuffer,
                    ref ppBuffer);
            if (Status == 0)
            {
                CRYPT_CONTEXT_FUNCTIONS functions = (CRYPT_CONTEXT_FUNCTIONS)Marshal.PtrToStructure(ppBuffer, typeof(CRYPT_CONTEXT_FUNCTIONS));
                
                IntPtr pStr = functions.rgpszFunctions;
                for (int i = 0; i < functions.cFunctions; i++)
                {
                    Console.WriteLine(Marshal.PtrToStringUni(Marshal.ReadIntPtr(pStr)));
                    pStr = new System.IntPtr((pStr.ToInt64()+(IntPtr.Size))) ;
                    // pStr += IntPtr.Size;
                    
                }
                BCryptFreeBuffer(ppBuffer);
            }
        }
    }
}
'@ -ErrorAction Stop
  } else {
     Write-Verbose -Message "Type already loaded" -Verbose
  }
# } Catch TYPE_ALREADY_EXISTS
} Catch {
  Write-Warning -Message "Failed because $($_.Exception.Message)"
}

[ConsoleApplication4.Program]::DoEnumCiphers()
