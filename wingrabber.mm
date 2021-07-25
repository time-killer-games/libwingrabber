#include <string>

#include <cstdlib>

#include <Cocoa/Cocoa.h>
#include <CoreGraphics/CoreGraphics.h>
#include <CoreFoundation/CoreFoundation.h>

#define EXPORTED_FUNCTION extern "C" __attribute__((visibility("default")))

namespace {

void window_get_size_from_id(char *window, int *width, int *height) {
  CFArrayRef windowArray = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
  CFIndex windowCount = 0;
  if ((windowCount = CFArrayGetCount(windowArray))) {
    for (CFIndex i = 0; i < windowCount; i++) {
      CFDictionaryRef windowInfoDictionary = 
      (CFDictionaryRef)CFArrayGetValueAtIndex(windowArray, i);
      CFNumberRef windowID = (CFNumberRef)CFDictionaryGetValue(
      windowInfoDictionary, kCGWindowNumber);
      CGWindowID wid; CFNumberGetValue(windowID,
      kCGWindowIDCFNumberType, &wid);
      if (strtoull(window, nullptr, 10) == wid) {
        CGRect rect; CFDictionaryRef dict = (CFDictionaryRef)CFDictionaryGetValue(
        windowInfoDictionary, kCGWindowBounds);
        CGRectMakeWithDictionaryRepresentation(dict, &rect);
        *width = CGRectGetWidth(rect);
        *height = CGRectGetHeight(rect);    
      }
    }
  }
  CFRelease(windowArray);
}

void copy_pixeldata(unsigned char *in, size_t width, size_t height, unsigned char **out) {
  int offset = 0;
  unsigned char *result = *out;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      result[offset + 0] = in[offset + 1];
      result[offset + 1] = in[offset + 2];
      result[offset + 2] = in[offset + 3];
      result[offset + 3] = in[offset + 0];
      offset += 4;
    }
  }
  *out = result;
}

} // anonymous namespace

EXPORTED_FUNCTION char *window_id_from_native_window(char *native) {
  static std::string window; 
  window = std::to_string([(NSWindow *)(void *)strtoull(native, nullptr, 10) windowNumber]);
  return (char *)window.c_str();
}

EXPORTED_FUNCTION char *native_window_from_window_id(char *window) {
  static std::string native; 
  native = std::to_string((unsigned long long)(void *)[NSApp windowWithWindowNumber:strtoull(window, nullptr, 10)]);
  return (char *)native.c_str();
}

EXPORTED_FUNCTION double window_get_width_from_id(char *window) {
  int width = 0, height = 0;
  window_get_size_from_id(window, &width, &height);
  return width;
}

EXPORTED_FUNCTION double window_get_height_from_id(char *window) {
  int width = 0, height = 0;
  window_get_size_from_id(window, &width, &height);
  return height;
}

EXPORTED_FUNCTION double window_grab_frame_buffer(char *window, char *buffer) {
  CGImageRef cgimage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, strtoull(window, nullptr, 10), kCGWindowImageBoundsIgnoreFraming);
  if (cgimage) {
    NSBitmapImageRep *nsbitmaprep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    if (nsbitmaprep) {
      unsigned char *dst = (unsigned char *)buffer;
      copy_pixeldata([nsbitmaprep bitmapData], 
      CGImageGetWidth(cgimage), CGImageGetHeight(cgimage), &dst);
      [nsbitmaprep release];
    }
    CGImageRelease(cgimage);
  }
  return 0;
}

