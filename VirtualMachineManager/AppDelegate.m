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
@property (weak) IBOutlet NSClipView *tblSnapshots;
@property (weak) IBOutlet NSTextField *vmPathText;
@property (weak) IBOutlet NSTextField *txtUsername;
@property (weak) IBOutlet NSTextField *txtPassword;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSComboBox *comboNetworkAdpaters;
@property (weak) IBOutlet NSTextField *txtIpAddress;
@property (weak) IBOutlet NSTextField *txtNetMask;
@property (weak) IBOutlet NSTextField *txtSnapshotName;
@property (weak) IBOutlet NSTextField *txtSnapshotDescription;
@property (weak) IBOutlet NSTextField *txtRevertSnapshotName;
@end

static NSString *const _VIXCompletionHandlerKey = @"block";

static NSString *const _VIXFoundItemsKey = @"foundItems";

static NSString *const _VIXHostKey = @"host";

NSMutableArray* networkInterfaces;

VixError vx_Error;

VixHandle hostHandle = VIX_INVALID_HANDLE;

VixHandle jobHandle = VIX_INVALID_HANDLE;

VixHandle vmHandle = VIX_INVALID_HANDLE;

VixHandle snapshotHandle = VIX_INVALID_HANDLE;

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
    [self powerOffVM];
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

- (IBAction)btnTakeMemorySnapshotDown:(id)sender {
    [self takeMemSnapshotWithName:[[self txtSnapshotName] stringValue] Description:  [ [self txtSnapshotDescription] stringValue]];
}

- (IBAction)btnDiskSnapshotDown:(id)sender {
    [self takeDiskSnapshotWithName:  [ [self txtSnapshotName] stringValue] Description:  [ [self txtSnapshotDescription] stringValue]];
}

- (IBAction)btnRevertSnapshotDown:(id)sender {
    [self revertSnapshotWithName:[[self txtRevertSnapshotName] stringValue]];
}

- (IBAction)btnSuspendDown:(id)sender {
    [self suspendVM];
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
        [alert setMessageText:@"Unable to Connect to VMWare Fusion"];
        [alert runModal];
    }
}


-(void) connectToVM{
    const char* vmPath = [[self.vmPathText stringValue] UTF8String];
    Vix_ReleaseHandle(jobHandle);
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
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_PowerOff(vmHandle,
                               VIX_VMPOWEROP_NORMAL,
                               NULL, // *callbackProc,
                               NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Unable to Power Off VM"];
        [alert runModal];
        [self Abort];
    }
}

-(void) loginToVM{
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_LoginInGuest(vmHandle,
                                   [[self.txtUsername stringValue] UTF8String],           // guest OS user
                                   [[self.txtPassword stringValue] UTF8String],           // guest OS passwd
                                   0,                        // options
                                   NULL,                     // callback
                                   NULL);                    // client data
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"failed to login to virtual machine"];
        [alert runModal];
        [self Abort];
    }
}

-(void) suspendVM {
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_Suspend(vmHandle,
                              VIX_VMPOWEROP_NORMAL,
                              NULL, // *callbackProc,
                              NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
}


-(void) findAllSnapshots {
    int numSnapshots;
    vx_Error = VixVM_GetNumRootSnapshots(vmHandle, &numSnapshots);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    
    NSLog(@"%zd", numSnapshots);
    
    if(numSnapshots > 0) {
        
        for (int i =0; i< numSnapshots; i++ ) {
            vx_Error = VixVM_GetRootSnapshot(vmHandle, i, &snapshotHandle);
            
            if (VIX_FAILED(vx_Error)) {
                [self Abort];
            }
            
            int  numChildSnapshots;
            vx_Error =  VixSnapshot_GetNumChildren(snapshotHandle, &numChildSnapshots);
            
            if (VIX_FAILED(vx_Error)) {
                [self Abort];
            }
            
            
            NSLog(@"%zd", numChildSnapshots);
          
            // NAME of SNAPSHOT!
            
        }
        
    }
}

-(void) takeMemSnapshotWithName:(NSString *) name Description:(NSString *) description {
    jobHandle = VixVM_CreateSnapshot(vmHandle,
                                     [name UTF8String],
                                     [description UTF8String] ,
                                     VIX_SNAPSHOT_INCLUDE_MEMORY,
                                     VIX_INVALID_HANDLE,
                                     NULL, // *callbackProc,
                                     NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle,
                           VIX_PROPERTY_JOB_RESULT_HANDLE,
                           &snapshotHandle,
                           VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    Vix_ReleaseHandle(jobHandle);
    Vix_ReleaseHandle(snapshotHandle);
}

-(void) takeDiskSnapshotWithName:(NSString *) name Description:(NSString *) description {
    jobHandle = VixVM_CreateSnapshot(vmHandle,
                                     [name UTF8String],
                                     [description UTF8String] ,
                                     0,
                                     VIX_INVALID_HANDLE,
                                     NULL, // *callbackProc,
                                     NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle,
                           VIX_PROPERTY_JOB_RESULT_HANDLE,
                           &snapshotHandle,
                           VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    Vix_ReleaseHandle(jobHandle);
    Vix_ReleaseHandle(snapshotHandle);
}




-(void) revertSnapshotWithName:(NSString *) name {
    
    vx_Error = VixVM_GetNamedSnapshot(vmHandle, [name UTF8String], &snapshotHandle);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    
    jobHandle = VixVM_RevertToSnapshot(vmHandle,
                                       snapshotHandle,
                                       VIX_VMPOWEROP_LAUNCH_GUI, // options,
                                       VIX_INVALID_HANDLE,
                                       NULL, // *callbackProc,
                                       NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    
    
}


-(void) revertSnapshotWithIndex:(NSInteger *) index {
    
    vx_Error = VixVM_GetRootSnapshot(vmHandle, (int)index, &snapshotHandle);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    
    jobHandle = VixVM_RevertToSnapshot(vmHandle,
                                      snapshotHandle,
                                      VIX_VMPOWEROP_LAUNCH_GUI, // options,
                                      VIX_INVALID_HANDLE,
                                      NULL, // *callbackProc,
                                      NULL); // *clientData);
    vx_Error = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(vx_Error)) {
        [self Abort];
    }
    
}

-(void) setIPAddress {
    //ip addr flush dev eth0

    NSString *address = [NSString stringWithFormat:@"%@%@%@", [self.txtIpAddress stringValue], @"/", [self.txtNetMask stringValue]];
    NSString *interfaceName = [self.comboNetworkAdpaters objectValueOfSelectedItem];
    NSString *flushIpCommand = [NSString stringWithFormat:@"%@%@", @"addr flush dev ",  interfaceName];
    NSString *setIpCommand = [NSString stringWithFormat:@"%@%@%@%@", @"addr add ", address, @" dev ", interfaceName];
    
    jobHandle = VixVM_RunProgramInGuest(vmHandle,
                                        "/sbin/ip",                // command
                                        [flushIpCommand UTF8String],   // cmd args
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
                                        "/sbin/ip",                // command
                                        [setIpCommand UTF8String],   // cmd args
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
        return;
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
        return;
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
        return;
    }
    
    NSString *retrieveFile = [NSString stringWithContentsOfFile:@NETWORK_INTERFACES encoding:NSUTF8StringEncoding error:nil];
    
    networkInterfaces = [[NSMutableArray alloc] initWithArray:[retrieveFile componentsSeparatedByString:@"\n\n"] copyItems: YES];
    
    [self.comboNetworkAdpaters removeAllItems];
    
    for(NSString* nic in networkInterfaces){
        if([nic length]>1){
            [self.comboNetworkAdpaters addItemWithObjectValue:[nic stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
        }
    }
}

-(void) Abort{
    NSLog(@"Vix_ReleaseHandle(jobHandle)");
    Vix_ReleaseHandle(jobHandle);
    NSLog(@"Vix_ReleaseHandle(vmHandle)");
    Vix_ReleaseHandle(vmHandle);
    NSLog(@"Vix_ReleaseHandle(snapshotHandle)");
    Vix_ReleaseHandle(snapshotHandle);
    NSLog(@"Vix_ReleaseHandle(hostHandle)");
    VixHost_Disconnect(hostHandle);
    
}



@end
