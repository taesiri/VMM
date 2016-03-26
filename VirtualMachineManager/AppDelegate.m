//
//  AppDelegate.m
//  VirtualMachineManager
//
//  Created by MohammadR Reza Taesiri on 3/26/16.
//  Copyright © 2016 Mohammad Reza Taesiri. All rights reserved.
//

#import "AppDelegate.h"

#import "vix.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSTextField *vmPathText;
@property (weak) IBOutlet NSTextField *txtUsername;
@property (weak) IBOutlet NSTextField *txtPassword;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSComboBox *comboNetworkAdpaters;
@property (weak) IBOutlet NSTextField *txtIpAddress;
@property (weak) IBOutlet NSTextField *txtNetMask;
@end

static NSString *const _VIXCompletionHandlerKey = @"block";

static NSString *const _VIXFoundItemsKey = @"foundItems";

static NSString *const _VIXHostKey = @"host";

NSMutableArray* networkInterfaces;

VixError vx_Error;

VixHandle hostHandle = VIX_INVALID_HANDLE;

VixHandle jobHandle = VIX_INVALID_HANDLE;

VixHandle vmHandle = VIX_INVALID_HANDLE;

#define NETWORK_INTERFACES "./netinterfaces.txt"



@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}




- (IBAction)btnConnectToFusionDown:(id)sender {
    [self connectToFusion];
}


- (IBAction)btnConnectToVMDown:(id)sender {
    [self connectToVM];
}

- (IBAction)btnPowerUpVMDown:(id)sender {
    [self powerUpVM];
}

- (IBAction)btnPowerOffVMDown:(id)sender {
    
}

- (IBAction)btnLoginDown:(id)sender {
    [self loginToVM];
}

- (IBAction)btnRefreshNetworkAdaptersDown:(id)sender {
    [self retrieveAdapterNames];
}

- (IBAction)btnSetIPDown:(id)sender {
    [self setIPAddress];
}


-(void)connectToFusion{
    jobHandle = VixHost_Connect(VIX_API_VERSION,
                                VIX_SERVICEPROVIDER_VMWARE_WORKSTATION,
                                NULL, // *hostName,
                                0, // hostPort,
                                NULL, // *userName,
                                NULL, // *password,
                                0, // options,
                                VIX_INVALID_HANDLE, // propertyListHandle,
                                NULL, // *callbackProc,
                                NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle,
                           VIX_PROPERTY_JOB_RESULT_HANDLE,
                           &hostHandle,
                           VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@""];
        [alert runModal];
    }
    Vix_ReleaseHandle(jobHandle);
}


-(void) connectToVM{
    const char* vmPath = [[self.vmPathText stringValue] UTF8String];
    jobHandle = VixVM_Open(hostHandle,
                           vmPath,
                           NULL, // VixEventProc *callbackProc,
                           NULL); // void *clientData);
    vx_Error = VixJob_Wait(jobHandle,
                           VIX_PROPERTY_JOB_RESULT_HANDLE,
                           &vmHandle,
                           VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Unable to Connect to VM"];
        [alert runModal];
        [self Abort];
    }
}


-(void)powerUpVM {
    NSLog(@"Powering It Up!");
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_PowerOn(vmHandle,
                              VIX_VMPOWEROP_LAUNCH_GUI,
                              VIX_INVALID_HANDLE,
                              NULL, // *callbackProc,
                              NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Unable to Power Up VM"];
        [alert runModal];
        [self Abort];
    }
    
}

-(void)powerOffVM{
    NSLog(@"Powering It Off!");
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_PowerOff(vmHandle,
                               VIX_VMPOWEROP_NORMAL,
                               NULL, // *callbackProc,
                               NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Unable to Power Off VM"];
        [alert runModal];
        [self Abort];
    }
}

-(void) loginToVM{
    const char* vmPath = [[self.vmPathText stringValue] UTF8String];
    jobHandle = VixVM_LoginInGuest(vmHandle,
                                   [[self.txtUsername stringValue] UTF8String],           // guest OS user
                                   [[self.txtPassword stringValue] UTF8String],           // guest OS passwd
                                   0,                        // options
                                   NULL,                     // callback
                                   NULL);                    // client data
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    Vix_ReleaseHandle(jobHandle);
    if (VIX_FAILED(vx_Error)) {
        fprintf(stderr, "failed to login to virtual machine '%s'(%"FMT64"d %s)\n", vmPath, vx_Error, Vix_GetErrorText(vx_Error, NULL));
        [self Abort];
    }
    
}

-(void) takeSnapshot{
    
    
}

-(void) revertSnapshot {
    
    
}

-(void) setIPAddress {
    NSString *address = [NSString stringWithFormat:@"%@%@%@", [self.txtIpAddress stringValue], @"/", [self.txtNetMask stringValue]];
    NSString *interfaceName = [self.comboNetworkAdpaters objectValueOfSelectedItem];
    NSString *command = [NSString stringWithFormat:@"%@%@%@%@", @"addr add ", address, @" dev ", interfaceName];
    
    
    jobHandle = VixVM_RunProgramInGuest(vmHandle,
                                        "/sbin/ip",                // command
                                        [command UTF8String],   // cmd args
                                        0,                        // options
                                        VIX_INVALID_HANDLE,       // prop handle
                                        NULL,                     // callback
                                        NULL);                    // client data
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    Vix_ReleaseHandle(jobHandle);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"failed to run program in virtual machine "];
        [alert runModal];
        [self Abort];
    }
    
}


-(void) retrieveAdapterNames{
    //ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d'
    jobHandle = VixVM_RunProgramInGuest(vmHandle,
                                        "/sbin/ifconfig",                // command
                                        "-a > /tmp/tmpnets",       // cmd args
                                        0,                        // options
                                        VIX_INVALID_HANDLE,       // prop handle
                                        NULL,                     // callback
                                        NULL);                    // client data
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    Vix_ReleaseHandle(jobHandle);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"failed to run program in virtual machine "];
        [alert runModal];
        [self Abort];
    }
    
    jobHandle = VixVM_RunProgramInGuest(vmHandle,
                                        "/bin/sed",                // command
                                        " 's/[ \\t].*//;/^\\(lo\\|\\)$/d' /tmp/tmpnets > /tmp/output",       // cmd args
                                        0,                        // options
                                        VIX_INVALID_HANDLE,       // prop handle
                                        NULL,                     // callback
                                        NULL);                    // client data
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    Vix_ReleaseHandle(jobHandle);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"failed to run program in virtual machine "];
        [alert runModal];
        [self Abort];
    }
    
    
    jobHandle = VixVM_CopyFileFromGuestToHost(vmHandle,
                                              "/tmp/output",            // src file
                                              NETWORK_INTERFACES,       // dst file
                                              0,                       // options
                                              VIX_INVALID_HANDLE,     // prop list
                                              NULL,                  // callback
                                              NULL);                // client data
    
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    Vix_ReleaseHandle(jobHandle);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"failed to copy file to the host"];
        [alert runModal];
        [self Abort];
    }
    
    
    
    NSString *retrieveFile = [NSString stringWithContentsOfFile:@NETWORK_INTERFACES encoding:NSUTF8StringEncoding error:nil];
    
    
    networkInterfaces = [[NSMutableArray alloc] initWithArray:[retrieveFile componentsSeparatedByString:@"\n\n"] copyItems: YES];
    
    
    for(NSString* nic in networkInterfaces){
        if([nic length]>1){
            [self.comboNetworkAdpaters addItemWithObjectValue:nic];
        }
    }
}

-(void) Abort{
    NSLog(@"Vix_ReleaseHandle(jobHandle)");
    Vix_ReleaseHandle(jobHandle);
    NSLog(@"Vix_ReleaseHandle(vmHandle)");
    Vix_ReleaseHandle(vmHandle);
    NSLog(@"Vix_ReleaseHandle(hostHandle)");
    VixHost_Disconnect(hostHandle);
}



@end
