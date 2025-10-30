# Custom Fonts in Live Activities

This package supports custom fonts in iOS Live Activities, allowing you to match the branding and typography of your main app.

## Overview

Custom fonts are used in the Golden Hour Live Activity countdown timers to maintain consistent branding with the GOLD app. The countdown displays use **Manrope-Bold**, matching the style of the app's `ClockCountdown` component.

## Font Setup

### 1. Font Files Location

Font files are stored in the `ios-files/Fonts/` directory:

```
ios-files/
├── Fonts/
│   ├── Manrope-Regular.ttf
│   ├── Manrope-Medium.ttf
│   ├── Manrope-SemiBold.ttf
│   ├── Manrope-Bold.ttf       ← Used in countdown timers
│   ├── Gunterz-Regular.ttf
│   ├── Gunterz-Medium.ttf
│   └── Gunterz-Bold.ttf
├── LiveActivityView.swift
├── LiveActivityWidget.swift
└── ...
```

### 2. Plugin Auto-Copy

The Expo config plugin automatically copies fonts to the widget extension during prebuild:

```typescript
// plugin/src/lib/getWidgetFiles.ts
// Copies ios-files/Fonts/ → ios/LiveActivity/Fonts/
```

### 3. Info.plist Registration

Fonts must be registered in the **widget extension's** `Info.plist` (not the main app's):

```xml
<!-- ios/LiveActivity/Info.plist -->
<key>UIAppFonts</key>
<array>
    <string>Manrope-Regular.ttf</string>
    <string>Manrope-Medium.ttf</string>
    <string>Manrope-SemiBold.ttf</string>
    <string>Manrope-Bold.ttf</string>
    <string>Gunterz-Regular.ttf</string>
    <string>Gunterz-Medium.ttf</string>
    <string>Gunterz-Bold.ttf</string>
</array>
```

**Note**: Widget extensions are separate binaries and need their own font registration.

### 4. Usage in Swift

Use `.font(.custom("FontName", size: points))` instead of system fonts:

```swift
// Lock Screen countdown (48pt)
Text(timerInterval: Date.toTimerInterval(miliseconds: endedTime), countsDown: true)
    .font(.custom("Manrope-Bold", size: 48))
    .monospacedDigit()

// Dynamic Island expanded view (32pt)
Text(timerInterval: Date.toTimerInterval(miliseconds: endedTime), countsDown: true)
    .font(.custom("Manrope-Bold", size: 32))
    .monospacedDigit()
```

## Font Name Reference

| Font File | PostScript Name | Usage |
|-----------|----------------|-------|
| `Manrope-Regular.ttf` | `Manrope-Regular` | Body text |
| `Manrope-Medium.ttf` | `Manrope-Medium` | Subheadings |
| `Manrope-SemiBold.ttf` | `Manrope-SemiBold` | Emphasis |
| `Manrope-Bold.ttf` | `Manrope-Bold` | **Countdown timers** |
| `Gunterz-Regular.ttf` | `Gunterz-Regular` | Brand headings |
| `Gunterz-Medium.ttf` | `Gunterz-Medium` | Brand emphasis |
| `Gunterz-Bold.ttf` | `Gunterz-Bold` | Strong brand |

## Adding New Fonts

To add additional custom fonts:

1. **Add font files** to `ios-files/Fonts/`
   ```bash
   cp MyFont-Bold.ttf ios-files/Fonts/
   ```

2. **Update Info.plist** (automatic during prebuild, but you may need to update manually if modifying the widget extension directly)
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>MyFont-Bold.ttf</string>
       <!-- existing fonts... -->
   </array>
   ```

3. **Find PostScript name** (required for `.font(.custom())` in Swift):
   ```bash
   # macOS
   fc-scan --format "%{postscriptname}\n" MyFont-Bold.ttf
   
   # Or install the font and use Font Book app
   ```

4. **Use in Swift**:
   ```swift
   .font(.custom("MyFont-Bold", size: 24))
   ```

5. **Rebuild** the app:
   ```bash
   cd ios && pod install
   # Then build in Xcode (⌘B)
   ```

## Xcode Configuration

### In Xcode Project:

1. **Add fonts to LiveActivity target**:
   - Select font files in Project Navigator
   - Check "LiveActivity" under Target Membership
   - Ensure "Copy items if needed" is checked

2. **Verify Info.plist**:
   - Select `LiveActivity` target
   - Go to Info tab
   - Check `UIAppFonts` array contains all font filenames

3. **Build Settings**:
   - No special settings required for custom fonts
   - Fonts are bundled automatically with widget extension

## Troubleshooting

### Font not appearing

1. **Check Info.plist registration**:
   ```bash
   # Verify fonts are listed
   plutil -p ios/LiveActivity/Info.plist | grep -A 20 UIAppFonts
   ```

2. **Verify font files exist**:
   ```bash
   ls -la ios/LiveActivity/Fonts/
   # Or check in Xcode's widget extension target
   ```

3. **Check PostScript name**:
   ```swift
   // In Swift, print available fonts
   for family in UIFont.familyNames.sorted() {
       print(family)
       for name in UIFont.fontNames(forFamilyName: family) {
           print("  \(name)")
       }
   }
   ```

4. **Rebuild widget extension**:
   ```bash
   # Clean build folder in Xcode
   Product → Clean Build Folder (⇧⌘K)
   
   # Delete derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### Font rendering issues

- **Monospaced digits**: Use `.monospacedDigit()` for countdown timers to prevent width changes
- **Size consistency**: Match font sizes with app's Typography component
- **Color contrast**: Ensure sufficient contrast on phase-colored backgrounds

## Related Files

- `ios-files/LiveActivityView.swift` - Lock Screen UI with 48pt countdown
- `ios-files/LiveActivityWidget.swift` - Dynamic Island UI with 32pt countdown
- `plugin/src/lib/getWidgetFiles.ts` - Auto-copies fonts during prebuild
- Main app's `libs/theme.ts` - Font family definitions for reference

## References

- [Apple: Adding a Custom Font](https://developer.apple.com/documentation/uikit/text_display_and_fonts/adding_a_custom_font_to_your_app)
- [Apple: Widget Extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [SwiftUI Font Modifiers](https://developer.apple.com/documentation/swiftui/font)
