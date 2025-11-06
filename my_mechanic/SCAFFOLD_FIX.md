# Image Upload ScaffoldMessenger Fix

## Issue
When uploading an image, the app crashed with the following error:
```
_AssertionError ('package:flutter/src/material/scaffold.dart': Failed assertion: line 329 pos 7: '_scaffolds.isNotEmpty': ScaffoldMessenger.showSnackBar was called, but there are currently no descendant Scaffolds to present to.)
```

## Root Cause
The `ScaffoldMessenger.of(context)` was being called after async operations (image picking and uploading), but the context was no longer valid or didn't have a Scaffold ancestor at that point.

## Solution
**Captured the ScaffoldMessenger and Navigator before any async operations:**

```dart
Future<void> _pickImage(ImageSource source) async {
  // Capture messenger before async operations
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  
  try {
    // ... async image picking and uploading ...
    
    // Use captured messenger instead of context
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Vehicle photo updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Use captured messenger for errors too
    messenger.showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Changes Made

### 1. `_pickImage()` method
- ✅ Captured `ScaffoldMessenger.of(context)` at the start
- ✅ Captured `Navigator.of(context)` at the start
- ✅ Used captured references instead of calling `of(context)` after async operations
- ✅ Added proper `mounted` checks before async operations
- ✅ Changed dialog to use `PopScope` for better control
- ✅ Removed unnecessary `rootNavigator: true` parameter

### 2. `_removeImage()` method
- ✅ Captured `ScaffoldMessenger.of(context)` at the start
- ✅ Used captured reference for all SnackBar calls
- ✅ Added `mounted` check after async dialog
- ✅ Cleaner error handling

## Why This Works

**The Problem:**
When you call `ScaffoldMessenger.of(context)` after an async operation, the `context` might:
1. No longer be mounted
2. Have changed its widget tree
3. Not have a Scaffold ancestor anymore

**The Solution:**
By capturing the `ScaffoldMessenger` reference **before** the async operations:
1. We get a valid reference while the context is still good
2. The messenger remains valid even after async operations
3. We can safely show SnackBars without context issues

## Testing
The fix ensures:
- ✅ Image upload success messages display correctly
- ✅ Error messages display correctly
- ✅ No crashes from missing Scaffold
- ✅ Loading dialog opens and closes properly
- ✅ Works across async boundaries

## Additional Safety
- Added `mounted` checks before showing dialogs
- Used captured Navigator for consistent navigation
- Wrapped dialog pop in try-catch for safety
- Removed risky `popUntil` logic

## Result
The image upload feature now works reliably without ScaffoldMessenger crashes! 🎉
