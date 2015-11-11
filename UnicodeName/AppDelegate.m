//
//  AppDelegate.m
//  UnicodeName
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

- (void)updateTable;

@end

@implementation AppDelegate

@synthesize inputCharacter = _inputCharacter;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRegisterServicesProvider( self, @"com.lifeaether.unicodename" );
    [self updateTable];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp terminate:nil];
}

- (void)setInputCharacter:(NSString *)inputCharacter
{
    _inputCharacter = inputCharacter;
    [self updateTable];
}

- (NSString *)inputCharacter
{
    return _inputCharacter;
}

- (void)pasteCharacter:(NSPasteboard *)pasteBoard userData:(NSString *)data error:(NSString **)errorString
{
    NSString *string = [pasteBoard stringForType:NSStringPboardType];
    [self setInputCharacter:string];
}

static NSArray * getUnicodeTable()
{
    static NSArray * unicodeTable = nil;
    static dispatch_once_t once;
    dispatch_once( &once, ^{
        NSMutableArray *table = [NSMutableArray array];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"UnicodeData_8_0_0" ofType:@"txt"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSScanner *scanner = [NSScanner scannerWithString:string];
        while ( ! [scanner isAtEnd] ) {
            unsigned int scannedCode = 0;
            NSString *scannedName = nil;
            [scanner scanHexInt:&scannedCode];
            [scanner scanString:@";" intoString:nil];
            [scanner scanUpToString:@";" intoString:&scannedName];
            [table addObject:@{@"code":[NSNumber numberWithInteger:scannedCode],@"name":scannedName}];
            [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
            [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
        }
        
        unicodeTable = [table sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"code" ascending:YES]]];
    });
    return unicodeTable;
}

static NSString * lookupUnicodeName( const NSUInteger code )
{
    NSArray *table = getUnicodeTable();
    NSUInteger index = [table indexOfObject:@{@"code":[NSNumber numberWithInteger:code]} inSortedRange:NSMakeRange(0, [table count]) options:NSBinarySearchingFirstEqual usingComparator:^(id obj1, id obj2){
        NSInteger i1 = [[obj1 valueForKey:@"code"] integerValue];
        NSInteger i2 = [[obj2 valueForKey:@"code"] integerValue];
        if ( i1 < i2 ) {
            return NSOrderedAscending;
        } else if ( i2 < i1 ) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];

    if ( index == NSNotFound ) {
        return @"";
    } else {
        return [[table objectAtIndex:index] valueForKey:@"name"];
    }
}

- (void)updateTable
{
    NSMutableArray *content = [NSMutableArray array];

    NSString *string = [self inputCharacter];
    const NSUInteger length = [string length];
    for ( NSInteger i = 0, count = 0; i < length; i++, count++ ) {
        const unichar c = [string characterAtIndex:i];
        NSRange range = NSMakeRange( i, 1 );
        if ( 0xD800 <= c && c <= 0xDBFF && i+1 < length ) {
            range.length = 2;
            i++;
        }
        
        NSString *character = [string substringWithRange:range];
        NSUInteger code = 0;
        if ( range.length == 1 ) {
            code = [character characterAtIndex:0];
        } else if ( range.length == 2 ) {
            code = 0x10000 + ([character characterAtIndex:0] - 0xD800) * 0x400 + ([character characterAtIndex:1] - 0xDC00);
        }
        
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:@{
                  @"index": [NSNumber numberWithInteger:count],
                  @"character": character,
                  @"code": [NSString stringWithFormat:@"%lX", (unsigned long)code]
                  }];
        [content addObject:item];
        
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *unicodeName = lookupUnicodeName(code);
            dispatch_async( dispatch_get_main_queue(), ^{
                [item setObject:unicodeName forKey:@"name"];
            });
        });
    }
    
    [[self unicodeArrayController] setContent:content];
}

@end
