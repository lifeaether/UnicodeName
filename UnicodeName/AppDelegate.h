//
//  AppDelegate.h
//  UnicodeName
//
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSArrayController *unicodeArrayController;
@property (copy) NSString *inputCharacter;

@end

