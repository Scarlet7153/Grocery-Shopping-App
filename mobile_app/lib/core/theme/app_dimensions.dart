/// Dimensions and spacing system following Material 3 design and Figma specifications
/// Consistent spacing and sizing for multi-role grocery shopping app
class AppDimensions {
  // SPACING SYSTEM - Based on 4dp grid system

  /// Extra Small Spacing - 4dp
  static const double spacingXs = 4.0;

  /// Small Spacing - 8dp
  static const double spacingS = 8.0;

  /// Medium Spacing - 12dp
  static const double spacingM = 12.0;

  /// Large Spacing - 16dp (base unit)
  static const double spacingL = 16.0;

  /// Extra Large Spacing - 20dp
  static const double spacingXl = 20.0;

  /// 2X Large Spacing - 24dp
  static const double spacing2Xl = 24.0;

  /// 3X Large Spacing - 32dp
  static const double spacing3Xl = 32.0;

  /// 4X Large Spacing - 40dp
  static const double spacing4Xl = 40.0;

  /// 5X Large Spacing - 48dp
  static const double spacing5Xl = 48.0;

  /// 6X Large Spacing - 56dp
  static const double spacing6Xl = 56.0;

  /// 7X Large Spacing - 64dp
  static const double spacing7Xl = 64.0;

  // PADDING VALUES - Common padding combinations

  /// Screen Edge Padding - Default horizontal screen padding
  static const double screenPadding = spacingL; // 16dp

  /// Screen Padding Large - For important screens
  static const double screenPaddingLarge = spacing2Xl; // 24dp

  /// Card Padding - Internal card padding
  static const double cardPadding = spacingL; // 16dp

  /// Card Padding Small - Compact cards
  static const double cardPaddingSmall = spacingM; // 12dp

  /// Button Padding Horizontal - Button side padding
  static const double buttonPaddingHorizontal = spacing2Xl; // 24dp

  /// Button Padding Vertical - Button top/bottom padding
  static const double buttonPaddingVertical = spacingM; // 12dp

  /// Input Padding - Text field internal padding
  static const double inputPadding = spacingL; // 16dp

  /// List Item Padding - List item internal padding
  static const double listItemPadding = spacingL; // 16dp

  // BORDER RADIUS VALUES - Rounded corners following Material 3

  /// Extra Small Radius - 4dp (small elements)
  static const double radiusXs = 4.0;

  /// Small Radius - 8dp (buttons, inputs)
  static const double radiusS = 8.0;

  /// Medium Radius - 12dp (cards, containers)
  static const double radiusM = 12.0;

  /// Large Radius - 16dp (important cards, modals)
  static const double radiusL = 16.0;

  /// Extra Large Radius - 20dp (featured elements)
  static const double radiusXl = 20.0;

  /// 2X Large Radius - 24dp (dialogs, sheets)
  static const double radius2Xl = 24.0;

  /// 3X Large Radius - 32dp (large containers)
  static const double radius3Xl = 32.0;

  /// Round Radius - 999dp (circular elements)
  static const double radiusRound = 999.0;

  // COMPONENT HEIGHTS - Standard heights for UI elements

  // Button Heights
  /// Small Button Height - 32dp
  static const double buttonHeightSmall = 32.0;

  /// Medium Button Height - 40dp
  static const double buttonHeightMedium = 40.0;

  /// Large Button Height - 48dp
  static const double buttonHeightLarge = 48.0;

  /// Extra Large Button Height - 56dp (primary actions)
  static const double buttonHeightXLarge = 56.0;

  // Input Field Heights
  /// Input Field Height - 48dp (standard text inputs)
  static const double inputHeight = 48.0;

  /// Input Field Large Height - 56dp (important inputs)
  static const double inputHeightLarge = 56.0;

  /// Text Area Min Height - 120dp (multiline inputs)
  static const double textAreaMinHeight = 120.0;

  // Navigation Heights
  /// App Bar Height - 56dp (standard app bar)
  static const double appBarHeight = 56.0;

  /// App Bar Large Height - 64dp (prominent app bar)
  static const double appBarHeightLarge = 64.0;

  /// Bottom Navigation Height - 80dp
  static const double bottomNavHeight = 80.0;

  /// Tab Bar Height - 48dp
  static const double tabBarHeight = 48.0;

  // List and Card Heights
  /// List Item Height - 56dp (single line)
  static const double listItemHeight = 56.0;

  /// List Item Large Height - 72dp (two line)
  static const double listItemHeightLarge = 72.0;

  /// Card Min Height - 120dp
  static const double cardMinHeight = 120.0;

  /// Product Card Height - 280dp
  static const double productCardHeight = 280.0;

  /// Category Card Height - 120dp
  static const double categoryCardHeight = 120.0;

  // ICON SIZES - Consistent icon sizing

  /// Extra Small Icon - 12dp
  static const double iconXs = 12.0;

  /// Small Icon - 16dp
  static const double iconS = 16.0;

  /// Medium Icon - 24dp (standard icons)
  static const double iconM = 24.0;

  /// Large Icon - 32dp (prominent icons)
  static const double iconL = 32.0;

  /// Extra Large Icon - 48dp (feature icons)
  static const double iconXl = 48.0;

  /// 2X Large Icon - 64dp (hero icons)
  static const double icon2Xl = 64.0;

  /// 3X Large Icon - 96dp (splash, empty states)
  static const double icon3Xl = 96.0;

  // AVATAR SIZES - Profile and user images

  /// Small Avatar - 32dp
  static const double avatarSmall = 32.0;

  /// Medium Avatar - 48dp
  static const double avatarMedium = 48.0;

  /// Large Avatar - 64dp
  static const double avatarLarge = 64.0;

  /// Extra Large Avatar - 96dp
  static const double avatarXLarge = 96.0;

  // ELEVATION VALUES - Shadow depths

  /// No Elevation - 0dp
  static const double elevationNone = 0.0;

  /// Low Elevation - 1dp (subtle shadows)
  static const double elevationLow = 1.0;

  /// Medium Elevation - 3dp (cards, buttons)
  static const double elevationMedium = 3.0;

  /// High Elevation - 6dp (floating elements)
  static const double elevationHigh = 6.0;

  /// Extra High Elevation - 12dp (modals, dialogs)
  static const double elevationXHigh = 12.0;

  /// Maximum Elevation - 24dp (overlays, notifications)
  static const double elevationMax = 24.0;

  // SCREEN BREAKPOINTS - Responsive design support

  /// Mobile Max Width - 768dp
  static const double mobileMaxWidth = 768.0;

  /// Tablet Max Width - 1024dp
  static const double tabletMaxWidth = 1024.0;

  /// Desktop Min Width - 1024dp
  static const double desktopMinWidth = 1024.0;

  // SPECIFIC COMPONENT DIMENSIONS

  // Search Bar
  /// Search Bar Height - 44dp
  static const double searchBarHeight = 44.0;

  // Chip Components
  /// Chip Height - 32dp
  static const double chipHeight = 32.0;

  /// Filter Chip Height - 40dp
  static const double filterChipHeight = 40.0;

  // Progress Indicators
  /// Progress Indicator Size - 24dp
  static const double progressIndicatorSize = 24.0;

  /// Progress Indicator Large - 48dp
  static const double progressIndicatorLarge = 48.0;

  // Divider
  /// Divider Thickness - 1dp
  static const double dividerThickness = 1.0;

  /// Thick Divider - 2dp
  static const double thickDividerThickness = 2.0;

  // Sliders and Controls
  /// Slider Track Height - 4dp
  static const double sliderTrackHeight = 4.0;

  /// Slider Thumb Size - 20dp
  static const double sliderThumbSize = 20.0;

  /// Switch Track Width - 52dp
  static const double switchTrackWidth = 52.0;

  /// Switch Track Height - 32dp
  static const double switchTrackHeight = 32.0;

  // IMAGE DIMENSIONS - Common image sizes

  /// Product Image Small - 80dp
  static const double productImageSmall = 80.0;

  /// Product Image Medium - 120dp
  static const double productImageMedium = 120.0;

  /// Product Image Large - 200dp
  static const double productImageLarge = 200.0;

  /// Banner Image Height - 160dp
  static const double bannerImageHeight = 160.0;

  /// Store Logo Size - 64dp
  static const double storeLogoSize = 64.0;

  // ANIMATION DURATIONS - Common animation timings (in milliseconds)

  /// Fast Animation - 150ms
  static const int animationFast = 150;

  /// Normal Animation - 300ms
  static const int animationNormal = 300;

  /// Slow Animation - 500ms
  static const int animationSlow = 500;

  /// Page Transition - 250ms
  static const int pageTransition = 250;

  // OPACITY VALUES - Common transparency levels

  /// Disabled Opacity - 38%
  static const double opacityDisabled = 0.38;

  /// Medium Emphasis Opacity - 60%
  static const double opacityMedium = 0.60;

  /// High Emphasis Opacity - 87%
  static const double opacityHigh = 0.87;

  /// Overlay Opacity - 50%
  static const double opacityOverlay = 0.50;

  /// Shimmer Opacity - 30%
  static const double opacityShimmer = 0.30;
}
