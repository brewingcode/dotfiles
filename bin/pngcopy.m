// http://www.alecjacobson.com/weblog/?p=3816
// build with:

//   $ clang -Wall -g -O3 -ObjC -framework Foundation -framework AppKit -o pngcopy pngcopy.m

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <unistd.h>

void usage()
{
    printf("Usage:\n\n"
      "Copy image file to clipboard:\n    pngcopy path/to/file\n\n"
      "Copy image data in stdin to clipboard:\n    cat /path/to/file | pngcopy -");
}

BOOL copy_to_clipboard(NSString *path)
{
  // http://stackoverflow.com/questions/2681630/how-to-read-png-image-to-nsimage
  NSImage * image;
  if([path isEqualToString:@"-"])
  {
    // http://caiustheory.com/read-standard-input-using-objective-c 
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    image = [[NSImage alloc] initWithData:[input readDataToEndOfFile]];
  }else
  { 
    image =  [[NSImage alloc] initWithContentsOfFile:path];
  }
  // http://stackoverflow.com/a/18124824/148668
  BOOL copied = false;
  if (image != nil)
  {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    NSArray *copiedObjects = [NSArray arrayWithObject:image];
    copied = [pasteboard writeObjects:copiedObjects];
    [pasteboard release];
  }
  [image release];
  return copied;
}

int main(int argc, char * const argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if(argc<2)
  {
    usage();
    return EXIT_FAILURE;
  }
  if(0 == strcmp(argv[1], "-h") || 0 == strcmp(argv[1], "--help"))
  {
    usage();
    return EXIT_SUCCESS;
  }
  NSString *path= [NSString stringWithUTF8String:argv[1]];
  BOOL success = copy_to_clipboard(path);
  [pool release];
  return (success?EXIT_SUCCESS:EXIT_FAILURE);
}
