import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Bottom navigation: the shop's home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation: the list of categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// Bottom navigation: what the customer is about to buy.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// Bottom navigation: the customer's own account and orders.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Cart screen: the heading in the top bar.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get cartTitle;

  /// Shown when the customer tries to add more of a product than there is stock.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{Only 1 in stock} other{Only {count} in stock}}'**
  String cartStockLimit(int count);

  /// Cart: how soon the order arrives, e.g. 'Delivery in 12 minutes'.
  ///
  /// In en, this message translates to:
  /// **'Delivery in {eta}'**
  String cartDeliveryIn(String eta);

  /// Cart: shown when the delivery time can't be worked out yet.
  ///
  /// In en, this message translates to:
  /// **'Delivery today'**
  String get cartDeliverySoon;

  /// Cart: how many items are in the delivery.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{Shipment of 1 item} other{Shipment of {count} items}}'**
  String cartShipment(int count);

  /// Cart item: takes the item out of the cart and saves it to the wishlist.
  ///
  /// In en, this message translates to:
  /// **'Move to wishlist'**
  String get cartMoveToWishlist;

  /// Cart: after an item was moved to the wishlist.
  ///
  /// In en, this message translates to:
  /// **'Moved to your wishlist'**
  String get cartMovedToWishlist;

  /// Cart: heading of products related to what's in the cart.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get cartYouMightLike;

  /// Product card and detail: stock is running low.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String productOnlyLeft(int count);

  /// Cart screen: placeholder inside the search field.
  ///
  /// In en, this message translates to:
  /// **'Search in your cart'**
  String get cartSearchHint;

  /// Cart screen: shown when the search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No item in your cart matches that.'**
  String get cartNoMatch;

  /// Cart screen: heading of the empty state.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// Cart screen: the line under the empty heading.
  ///
  /// In en, this message translates to:
  /// **'Add items from the store to get started'**
  String get cartEmptyBody;

  /// Cart screen: button on the empty state, goes to the shop.
  ///
  /// In en, this message translates to:
  /// **'Browse Products'**
  String get cartBrowse;

  /// Cart screen: the cart could not be fetched from the server.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your cart'**
  String get cartLoadFailed;

  /// Cart screen: a background write of the cart to the server failed; the resend button is beside this notice.
  ///
  /// In en, this message translates to:
  /// **'Some changes could not reach the server. Your cart on this phone is right — resend it before you check out.'**
  String get cartSyncFailed;

  /// Cart screen: button that resends the whole cart to the server after a failed background write.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get cartSyncRetry;

  /// Cart screen: button that empties the cart, asks first.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get cartClear;

  /// Cart screen: heading of the confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get cartClearTitle;

  /// Cart screen: the question inside that dialog.
  ///
  /// In en, this message translates to:
  /// **'All items will be removed from your cart.'**
  String get cartClearBody;

  /// Cart screen: dialog button that does not empty the cart.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get cartKeep;

  /// Cart screen: dialog button that does empty the cart.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cartClearAction;

  /// Cart screen: heading of the bill breakdown card.
  ///
  /// In en, this message translates to:
  /// **'Bill Details'**
  String get cartBillDetails;

  /// Cart: how much the discounts on the items add up to.
  ///
  /// In en, this message translates to:
  /// **'You\'re saving {amount} on this order'**
  String cartYouSave(String amount);

  /// Cart: how much more to add before delivery becomes free.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more for FREE delivery'**
  String cartFreeDeliveryShort(String amount);

  /// Cart: the order is big enough for free delivery.
  ///
  /// In en, this message translates to:
  /// **'Yay! You get FREE delivery'**
  String get cartFreeDeliveryUnlocked;

  /// Cart screen: bill line naming how many items are in the cart.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String cartItemsCount(int count);

  /// Cart screen: bill line for the delivery charge.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get cartDeliveryFee;

  /// Cart screen: shown instead of a delivery charge when there is none.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get cartFree;

  /// Cart screen: the same button for someone who is not signed in.
  ///
  /// In en, this message translates to:
  /// **'Login to Checkout'**
  String get cartLoginToCheckout;

  /// Wishlist screen: the heading in the top bar.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get wishlistTitle;

  /// Wishlist screen: the saved items could not be fetched from the server.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your wishlist'**
  String get wishlistLoadFailed;

  /// Wishlist screen: heading of the dialog that asks before emptying the wishlist.
  ///
  /// In en, this message translates to:
  /// **'Clear Wishlist?'**
  String get wishlistClearTitle;

  /// Wishlist screen: the question in the clear-wishlist dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove all items from your wishlist?'**
  String get wishlistClearBody;

  /// Wishlist screen: button that closes the clear-wishlist dialog without clearing.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wishlistCancel;

  /// Wishlist screen: button that empties the wishlist (top bar and dialog).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wishlistClear;

  /// Wishlist screen: heading of the empty state.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmptyTitle;

  /// Wishlist screen: the empty state's hint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on products to save them here.'**
  String get wishlistEmptyBody;

  /// Wishlist screen: button on the empty state, goes back to the shop.
  ///
  /// In en, this message translates to:
  /// **'Browse Products'**
  String get wishlistBrowse;

  /// Wishlist screen: how many products are saved, above the grid.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String wishlistItemsCount(int count);

  /// Wishlist screen: notice after all saved items are added to the cart.
  ///
  /// In en, this message translates to:
  /// **'{count} items added to cart!'**
  String wishlistAddedToCart(int count);

  /// Wishlist screen: the bottom button that adds every saved item to the cart.
  ///
  /// In en, this message translates to:
  /// **'ADD ALL TO CART'**
  String get wishlistAddAll;

  /// Orders screen: the heading in the top bar.
  ///
  /// In en, this message translates to:
  /// **'Your Orders'**
  String get ordersTitle;

  /// Orders screen: the order list could not be fetched from the server.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your orders'**
  String get ordersLoadFailed;

  /// Orders screen: heading of the empty state.
  ///
  /// In en, this message translates to:
  /// **'No orders yet!'**
  String get ordersEmptyTitle;

  /// Orders screen: the empty state's hint.
  ///
  /// In en, this message translates to:
  /// **'Start shopping to place your first order.'**
  String get ordersEmptyBody;

  /// Orders screen: label of the total line on each order card.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ordersTotal;

  /// Wallet screen: the heading in the top bar.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get walletTitle;

  /// Wallet screen: label above the balance amount.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get walletBalanceLabel;

  /// Wallet screen: heading above the list of transactions.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get walletHistoryTitle;

  /// Wallet screen: the balance/transactions could not be fetched from the server.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your wallet'**
  String get walletLoadFailed;

  /// Wallet screen: the empty state of the transaction list.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletEmpty;

  /// Payment methods screen: the heading in the top bar.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethodsTitle;

  /// Payment methods screen: the saved methods could not be fetched from the server.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your payment methods'**
  String get paymentMethodsLoadFailed;

  /// Payment methods screen: heading of the add-method dialog.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get paymentMethodsAddTitle;

  /// Payment methods screen: the UPI choice in the add dialog's type selector.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get paymentMethodsUpi;

  /// Payment methods screen: the card choice in the add dialog's type selector.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodsCard;

  /// Payment methods screen: field label for the UPI app's name.
  ///
  /// In en, this message translates to:
  /// **'UPI app name'**
  String get paymentMethodsUpiLabel;

  /// Payment methods screen: field label for the card's bank/name.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get paymentMethodsCardLabel;

  /// Payment methods screen: example inside the UPI app name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Google Pay'**
  String get paymentMethodsUpiLabelHint;

  /// Payment methods screen: example inside the card name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. HDFC Bank'**
  String get paymentMethodsCardLabelHint;

  /// Payment methods screen: field label for the UPI ID.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get paymentMethodsUpiDetail;

  /// Payment methods screen: field label for the card's last four digits.
  ///
  /// In en, this message translates to:
  /// **'Card last 4 digits'**
  String get paymentMethodsCardDetail;

  /// Payment methods screen: example inside the UPI ID field.
  ///
  /// In en, this message translates to:
  /// **'name@upi'**
  String get paymentMethodsUpiDetailHint;

  /// Payment methods screen: example inside the last-4-digits field.
  ///
  /// In en, this message translates to:
  /// **'•••• 1234'**
  String get paymentMethodsCardDetailHint;

  /// Payment methods screen: button that closes the add dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get paymentMethodsCancel;

  /// Payment methods screen: button that saves the new method.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get paymentMethodsSave;

  /// Payment methods screen: the empty state.
  ///
  /// In en, this message translates to:
  /// **'No payment methods saved'**
  String get paymentMethodsEmpty;

  /// Payment methods screen: badge marking the default method.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get paymentMethodsDefaultBadge;

  /// Payment methods screen: button that makes a method the default.
  ///
  /// In en, this message translates to:
  /// **'Set default'**
  String get paymentMethodsSetDefault;

  /// Payment methods screen: notice when making a method the default fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t set this as your default. Check your connection and try again.'**
  String get paymentMethodsSetDefaultFailed;

  /// Payment methods screen: notice when removing a method fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove this payment method. Check your connection and try again.'**
  String get paymentMethodsDeleteFailed;

  /// Notifications screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Notifications screen: shown when the inbox could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notifications'**
  String get notificationsLoadFailed;

  /// Notifications screen: notice when an action on a notification fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update that. Please try again.'**
  String get notificationsUpdateFailed;

  /// Notifications screen: snack-bar button that reverses the last action.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get notificationsUndo;

  /// Notifications screen: notice after archiving one notification.
  ///
  /// In en, this message translates to:
  /// **'Notification archived'**
  String get notificationsArchived;

  /// Notifications screen: notice after restoring one notification.
  ///
  /// In en, this message translates to:
  /// **'Moved back to inbox'**
  String get notificationsUnarchived;

  /// Notifications screen: notice after deleting one notification.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationsDeleted;

  /// Notifications screen: notice after marking every notification read.
  ///
  /// In en, this message translates to:
  /// **'All marked as read'**
  String get notificationsAllRead;

  /// Notifications screen: notice after archiving every notification.
  ///
  /// In en, this message translates to:
  /// **'{count} archived'**
  String notificationsArchiveAllDone(int count);

  /// Notifications screen: title of the clear-inbox confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear all?'**
  String get notificationsClearAllTitle;

  /// Notifications screen: title of the clear-archive confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear archive?'**
  String get notificationsClearArchiveTitle;

  /// Notifications screen: body of the clear confirmation dialog. The count is how many notifications will be deleted.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes {count,plural,=1{1 notification} other{{count} notifications}}. It can\'t be undone.'**
  String notificationsClearConfirm(int count);

  /// Notifications screen: button that closes the clear dialog without deleting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notificationsCancel;

  /// Notifications screen: button and swipe label that deletes a notification.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationsDelete;

  /// Notifications screen: notice after clearing a list.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get notificationsCleared;

  /// Notifications screen: tooltip of the app-bar overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get notificationsMore;

  /// Notifications screen: menu item that marks the whole inbox read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// Notifications screen: menu item that archives the whole inbox.
  ///
  /// In en, this message translates to:
  /// **'Archive all'**
  String get notificationsArchiveAll;

  /// Notifications screen: menu item that empties the inbox.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notificationsClearAll;

  /// Notifications screen: menu item that empties the archive.
  ///
  /// In en, this message translates to:
  /// **'Clear archive'**
  String get notificationsClearArchive;

  /// Notifications screen: name of the inbox tab.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get notificationsInbox;

  /// Notifications screen: inbox tab name with the number of unread notifications.
  ///
  /// In en, this message translates to:
  /// **'Inbox ({count})'**
  String notificationsInboxCount(int count);

  /// Notifications screen: name of the archived tab.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get notificationsArchivedTab;

  /// Notifications screen: hint above the inbox list explaining the swipe actions.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to archive  •  left to delete'**
  String get notificationsSwipeHintInbox;

  /// Notifications screen: hint above the archived list explaining the swipe actions.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to move back to inbox  •  left to delete'**
  String get notificationsSwipeHintArchive;

  /// Notifications screen: swipe label and menu item that restores a notification.
  ///
  /// In en, this message translates to:
  /// **'Move to inbox'**
  String get notificationsMoveToInbox;

  /// Notifications screen: swipe label and menu item that archives a notification.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get notificationsArchive;

  /// Notifications screen: heading of the empty archive.
  ///
  /// In en, this message translates to:
  /// **'Nothing archived'**
  String get notificationsEmptyArchivedTitle;

  /// Notifications screen: heading of the empty inbox.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmptyTitle;

  /// Notifications screen: line under the empty archive heading.
  ///
  /// In en, this message translates to:
  /// **'Archived notifications show up here.'**
  String get notificationsEmptyArchivedBody;

  /// Notifications screen: line under the empty inbox heading.
  ///
  /// In en, this message translates to:
  /// **'New notifications will show up here.'**
  String get notificationsEmptyBody;

  /// Notifications screen: time label for a notification from this minute.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// Notifications screen: time label in minutes, e.g. 5m ago.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationsMinutesAgo(int count);

  /// Notifications screen: time label in hours, e.g. 3h ago.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notificationsHoursAgo(int count);

  /// Notifications screen: time label in days, e.g. 2d ago.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String notificationsDaysAgo(int count);

  /// Notifications screen: tooltip of a notification's own menu.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get notificationsOptions;

  /// Notifications screen: menu item that marks one notification read.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationsMarkRead;

  /// Notifications screen: menu item that marks one notification unread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get notificationsMarkUnread;

  /// Brands screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Shop by Brand'**
  String get brandsTitle;

  /// Brands screen: shown when the brand list could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the brands'**
  String get brandsLoadFailed;

  /// Brands screen: shown when the list loaded but is empty.
  ///
  /// In en, this message translates to:
  /// **'No brands available yet.'**
  String get brandsEmpty;

  /// Order support screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Order Help'**
  String get orderSupportTitle;

  /// Order support screen: shown when the tickets could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order\'s tickets'**
  String get orderSupportLoadFailed;

  /// Order support screen: title of the dialog for filing a return.
  ///
  /// In en, this message translates to:
  /// **'Request a Return'**
  String get orderSupportRequestReturn;

  /// Order support screen: dialog title and button for reporting a problem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get orderSupportReportProblem;

  /// Order support screen: the button that opens the return dialog.
  ///
  /// In en, this message translates to:
  /// **'Request Return'**
  String get orderSupportRequestReturnButton;

  /// Order support screen: label of the short reason field.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get orderSupportReason;

  /// Order support screen: label of the details field.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get orderSupportDescription;

  /// Order support screen: button that closes the dialog without submitting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get orderSupportCancel;

  /// Order support screen: button that files the ticket.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get orderSupportSubmit;

  /// Order support screen: notice after a ticket was filed.
  ///
  /// In en, this message translates to:
  /// **'Your request has been submitted.'**
  String get orderSupportSubmitted;

  /// Order support screen: notice when filing a ticket fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit this request. It may be outside the eligible window.'**
  String get orderSupportSubmitFailed;

  /// Order support screen: heading above the reported problems.
  ///
  /// In en, this message translates to:
  /// **'Reported Issues'**
  String get orderSupportIssuesHeading;

  /// Order support screen: heading above the return requests.
  ///
  /// In en, this message translates to:
  /// **'Return Requests'**
  String get orderSupportReturnsHeading;

  /// Order support screen: shown when this order has no tickets.
  ///
  /// In en, this message translates to:
  /// **'No issues or return requests for this order yet.'**
  String get orderSupportEmpty;

  /// About screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get helpAboutTitle;

  /// About screen: heading of the first paragraph.
  ///
  /// In en, this message translates to:
  /// **'duggu'**
  String get helpAboutDugguHeading;

  /// About screen: what Duggu is.
  ///
  /// In en, this message translates to:
  /// **'Duggu brings groceries, daily needs and festival shopping from stores near you to your door, fast.'**
  String get helpAboutDugguBody;

  /// About screen: heading about where orders come from.
  ///
  /// In en, this message translates to:
  /// **'Local stores'**
  String get helpAboutStoresHeading;

  /// About screen: how orders are fulfilled and timed.
  ///
  /// In en, this message translates to:
  /// **'Every order is fulfilled by a real store close to your address. The delivery time you see is worked out from where you are and where the nearest store is.'**
  String get helpAboutStoresBody;

  /// About screen: heading about sellers, partners and payment.
  ///
  /// In en, this message translates to:
  /// **'Made for neighbourhoods'**
  String get helpAboutNeighbourhoodsHeading;

  /// About screen: who does what, and how you can pay.
  ///
  /// In en, this message translates to:
  /// **'Sellers list their own products and prices, delivery partners bring them to you, and you pay how you like: cash on delivery, online or from your Duggu wallet.'**
  String get helpAboutNeighbourhoodsBody;

  /// Policies screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get helpPoliciesTitle;

  /// Policies screen: heading of the privacy note.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get helpPolicyPrivacyHeading;

  /// Policies screen: what is kept and why.
  ///
  /// In en, this message translates to:
  /// **'We keep the details you give us (name, email, phone number, delivery addresses) and your order history so we can deliver your orders and show them back to you. Your location is used only when you choose \"Use current location\" or set an address on the map.'**
  String get helpPolicyPrivacyBody;

  /// Policies screen: heading of the payments note.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get helpPolicyPaymentsHeading;

  /// Policies screen: who handles online payments.
  ///
  /// In en, this message translates to:
  /// **'Online payments are handled by Razorpay. Duggu never sees or stores your card or UPI details.'**
  String get helpPolicyPaymentsBody;

  /// Policies screen: heading of the delivery-fee note.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get helpPolicyDeliveryHeading;

  /// Policies screen: when the delivery fee applies. The two amounts are already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'A delivery fee of {fee} applies to each store\'s part of an order under {threshold}; above that it is free.'**
  String helpPolicyDeliveryBody(String fee, String threshold);

  /// Policies screen: heading of the cancellation note.
  ///
  /// In en, this message translates to:
  /// **'Cancellations and refunds'**
  String get helpPolicyRefundsHeading;

  /// Policies screen: when an order can be cancelled and where the money goes.
  ///
  /// In en, this message translates to:
  /// **'An order can be cancelled from My Orders while the store has not sent it out. Money you paid from your Duggu wallet goes back to the wallet.'**
  String get helpPolicyRefundsBody;

  /// Policies screen: heading of the returns note.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get helpPolicyReturnsHeading;

  /// Policies screen: the return window.
  ///
  /// In en, this message translates to:
  /// **'Delivered orders can be reported or returned from the order\'s page within 10 days of delivery.'**
  String get helpPolicyReturnsBody;

  /// Terms screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get helpTermsTitle;

  /// Terms screen: heading of the account note.
  ///
  /// In en, this message translates to:
  /// **'Using Duggu'**
  String get helpTermsUsingHeading;

  /// Terms screen: account and details.
  ///
  /// In en, this message translates to:
  /// **'You need an account to place orders. Please keep your login private and give correct details, especially your delivery address and phone number.'**
  String get helpTermsUsingBody;

  /// Terms screen: heading of the pricing note.
  ///
  /// In en, this message translates to:
  /// **'Prices and stock'**
  String get helpTermsPricesHeading;

  /// Terms screen: who sets prices and when they are checked.
  ///
  /// In en, this message translates to:
  /// **'Prices and availability are set by each store and are checked again when you place the order. If something is out of stock the order cannot be placed as it is.'**
  String get helpTermsPricesBody;

  /// Terms screen: heading of the coupon note.
  ///
  /// In en, this message translates to:
  /// **'Coupons and wallet'**
  String get helpTermsCouponsHeading;

  /// Terms screen: the coupon and wallet rules.
  ///
  /// In en, this message translates to:
  /// **'A coupon can be used once per account and only above its minimum order value. Wallet money can only be spent on Duggu orders.'**
  String get helpTermsCouponsBody;

  /// Terms screen: heading of the fair-use note.
  ///
  /// In en, this message translates to:
  /// **'Fair use'**
  String get helpTermsFairUseHeading;

  /// Terms screen: what misuse leads to.
  ///
  /// In en, this message translates to:
  /// **'We may limit or close accounts that misuse offers, the wallet or referral bonuses.'**
  String get helpTermsFairUseBody;

  /// FAQ screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get helpFaqTitle;

  /// FAQ screen: question about the delivery-time estimate.
  ///
  /// In en, this message translates to:
  /// **'How is the delivery time worked out?'**
  String get helpFaqDeliveryTimeQuestion;

  /// FAQ screen: answer about the delivery-time estimate.
  ///
  /// In en, this message translates to:
  /// **'From your delivery address and the nearest store that can serve you. Set your address at the top of the home page to see it.'**
  String get helpFaqDeliveryTimeAnswer;

  /// FAQ screen: question about delivery charges.
  ///
  /// In en, this message translates to:
  /// **'What are the delivery charges?'**
  String get helpFaqChargesQuestion;

  /// FAQ screen: answer about delivery charges. The two amounts are already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'{fee} for each store\'s part of your order, and free when that part is {threshold} or more.'**
  String helpFaqChargesAnswer(String fee, String threshold);

  /// FAQ screen: question about payment methods.
  ///
  /// In en, this message translates to:
  /// **'How can I pay?'**
  String get helpFaqPayQuestion;

  /// FAQ screen: answer about payment methods.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery, online (UPI and cards) or from your Duggu wallet. You can use wallet money together with either of the other two.'**
  String get helpFaqPayAnswer;

  /// FAQ screen: question about stacking coupons.
  ///
  /// In en, this message translates to:
  /// **'Can I use more than one coupon?'**
  String get helpFaqCouponsQuestion;

  /// FAQ screen: answer about stacking coupons.
  ///
  /// In en, this message translates to:
  /// **'One coupon per order, and each coupon can be used once per account.'**
  String get helpFaqCouponsAnswer;

  /// FAQ screen: question about cancelling.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel an order?'**
  String get helpFaqCancelQuestion;

  /// FAQ screen: answer about cancelling.
  ///
  /// In en, this message translates to:
  /// **'Open it from Orders. If the store has not sent it out yet you will see the option to cancel. Wallet money you used is refunded to the wallet.'**
  String get helpFaqCancelAnswer;

  /// FAQ screen: question about a problem with an order.
  ///
  /// In en, this message translates to:
  /// **'Something was wrong with my order'**
  String get helpFaqWrongItemQuestion;

  /// FAQ screen: answer about reporting a problem.
  ///
  /// In en, this message translates to:
  /// **'Open the order from Orders and report the problem or ask for a return. Returns can be asked for within 10 days of delivery.'**
  String get helpFaqWrongItemAnswer;

  /// FAQ screen: question about referrals.
  ///
  /// In en, this message translates to:
  /// **'How does the referral bonus work?'**
  String get helpFaqReferralQuestion;

  /// FAQ screen: answer about referrals. The amount is already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'When a friend signs up with your referral code, you both get {amount} in your wallet.'**
  String helpFaqReferralAnswer(String amount);

  /// FAQ screen: question about asking for a product.
  ///
  /// In en, this message translates to:
  /// **'A product I want is not in the store'**
  String get helpFaqMissingProductQuestion;

  /// FAQ screen: answer about asking for a product.
  ///
  /// In en, this message translates to:
  /// **'Ask for it under Profile, Product Requests.'**
  String get helpFaqMissingProductAnswer;

  /// Contact screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get helpContactTitle;

  /// Contact screen: the line above the form.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you need help with and we will get back to you.'**
  String get helpContactIntro;

  /// Contact screen: label of the subject field.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get helpContactSubject;

  /// Contact screen: label of the message field.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get helpContactMessage;

  /// Contact screen: the button that sends the message.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get helpContactSend;

  /// Contact screen: notice after the message was sent.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we got your message.'**
  String get helpContactSent;

  /// Shown on a button while a form is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get helpSending;

  /// Shown when a form could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Try again.'**
  String get helpSendFailed;

  /// Product requests screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Product Requests'**
  String get helpRequestsTitle;

  /// Product requests screen: the line above the form.
  ///
  /// In en, this message translates to:
  /// **'Cannot find something? Tell us what you would like to see in the store.'**
  String get helpRequestsIntro;

  /// Product requests screen: label of the product-name field.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get helpRequestsName;

  /// Product requests screen: label of the details field.
  ///
  /// In en, this message translates to:
  /// **'Brand, size or anything else (optional)'**
  String get helpRequestsDetails;

  /// Product requests screen: the button that files the request.
  ///
  /// In en, this message translates to:
  /// **'Request product'**
  String get helpRequestsSend;

  /// Product requests screen: notice after the request was filed.
  ///
  /// In en, this message translates to:
  /// **'Request sent.'**
  String get helpRequestsSent;

  /// Product requests screen: shown when the earlier requests could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your requests.'**
  String get helpRequestsLoadFailed;

  /// Product requests screen: heading above the requests already filed.
  ///
  /// In en, this message translates to:
  /// **'Your requests'**
  String get helpRequestsMine;

  /// Product requests screen: status of a request that was handled.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get helpRequestDone;

  /// Product requests screen: status of a request still to be handled.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get helpRequestOpen;

  /// Rate-us sheet: the heading above the stars.
  ///
  /// In en, this message translates to:
  /// **'How is your experience with Duggu?'**
  String get helpRateTitle;

  /// Rate-us sheet: label of the note field.
  ///
  /// In en, this message translates to:
  /// **'Tell us more (optional)'**
  String get helpRateNote;

  /// Rate-us sheet: the button that sends the rating.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get helpRateSubmit;

  /// Rate-us sheet: notice after the rating was sent.
  ///
  /// In en, this message translates to:
  /// **'Thank you for rating Duggu.'**
  String get helpRateThanks;

  /// The message the Share App row hands to the phone's share sheet.
  ///
  /// In en, this message translates to:
  /// **'Try Duggu: groceries and daily needs from stores near you, delivered fast.'**
  String get helpShareMessage;

  /// Profile screen: the heading above the account card.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// Profile screen: notice when the new photo could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Could not update your photo.'**
  String get profileAvatarFailed;

  /// Profile screen: notice when becoming a seller or delivery partner failed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch role. Try again.'**
  String get profileRoleSwitchFailed;

  /// Profile screen: row and dialog title for opening a store.
  ///
  /// In en, this message translates to:
  /// **'Become a Seller'**
  String get profileBecomeSeller;

  /// Profile screen: label of the store-name field.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get profileBusinessName;

  /// Profile screen: label of the owner-name field.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get profileOwnerName;

  /// Profile screen: button that closes a dialog without submitting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// Profile screen: button that sends a dialog's form.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get profileSubmit;

  /// Profile screen: row and dialog title for delivering with Duggu.
  ///
  /// In en, this message translates to:
  /// **'Become a Delivery Partner'**
  String get profileBecomeDelivery;

  /// Profile screen: label of the full-name field.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// Profile screen: label of the vehicle dropdown.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get profileVehicleType;

  /// Profile screen: vehicle choice.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get profileVehicleBike;

  /// Profile screen: vehicle choice.
  ///
  /// In en, this message translates to:
  /// **'Scooter'**
  String get profileVehicleScooter;

  /// Profile screen: vehicle choice.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get profileVehicleBicycle;

  /// Profile screen: vehicle choice.
  ///
  /// In en, this message translates to:
  /// **'EV Scooter'**
  String get profileVehicleEvScooter;

  /// Profile screen: note when the account details never arrived.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your account details.'**
  String get profileStale;

  /// Profile screen: heading of the orders, wallet and saved-things rows.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get profileSectionPersonal;

  /// Profile screen: heading of the app settings rows.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get profileSectionSettings;

  /// Profile screen: heading of the help rows.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileSectionHelp;

  /// Profile screen: heading of the about and share rows.
  ///
  /// In en, this message translates to:
  /// **'About & Community'**
  String get profileSectionAbout;

  /// Profile screen: heading of the become-a-seller / become-a-partner rows.
  ///
  /// In en, this message translates to:
  /// **'Work with Duggu'**
  String get profileSectionWork;

  /// Profile screen: row that opens the order list.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get profileMyOrders;

  /// Profile screen: row that opens the saved addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get profileAddresses;

  /// Profile screen: row that opens the wallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get profileMyWallet;

  /// Profile screen: row that opens the saved payment methods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get profilePaymentMethods;

  /// Profile screen: row that opens the wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get profileWishlist;

  /// Profile screen: row holding the night-sky switch.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get profileChangeTheme;

  /// Profile screen: row that opens the contact form.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get profileContactUs;

  /// Profile screen: row that opens the questions page.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get profileFaq;

  /// Profile screen: row that opens the product-request form.
  ///
  /// In en, this message translates to:
  /// **'Product Requests'**
  String get profileProductRequests;

  /// Profile screen: row that opens the policies page.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get profilePolicies;

  /// Profile screen: row that opens the terms page.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get profileTerms;

  /// Profile screen: row that opens the notification inbox.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get profileNotifications;

  /// Profile screen: row that opens the about page.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get profileAbout;

  /// Profile screen: row that opens the rating sheet.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get profileRateUs;

  /// Profile screen: row that opens the phone's share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get profileShareApp;

  /// Profile screen: row that signs the person out.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// Profile: permanently deletes the customer's own account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// Profile: title of the delete-account confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteTitle;

  /// Profile: what deleting the account does.
  ///
  /// In en, this message translates to:
  /// **'Your name, phone, addresses, cart, wishlist and saved payment methods will be removed and you won\'t be able to sign in again. Past orders stay with the store, without your address. This can\'t be undone.'**
  String get profileDeleteBody;

  /// Profile: confirm button of the delete-account dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDeleteConfirm;

  /// Profile: cancel button of the delete-account dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get profileDeleteKeep;

  /// Profile: account can't be deleted while an order is active.
  ///
  /// In en, this message translates to:
  /// **'You have an order on its way. Delete your account once it\'s delivered or cancelled.'**
  String get profileDeleteActiveOrders;

  /// Profile: account deletion failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Please try again.'**
  String get profileDeleteFailed;

  /// Profile: shown after the account was deleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get profileDeleted;

  /// Profile screen: shown in place of a missing name.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get profileWelcomeName;

  /// Profile screen: greeting for someone not signed in.
  ///
  /// In en, this message translates to:
  /// **'Welcome to duggu'**
  String get profileWelcomeGuest;

  /// Profile screen: button that opens the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get profileLogin;

  /// Profile screen: referral row when the code could not be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your friends code — tap to retry'**
  String get profileReferralFailed;

  /// Profile screen: the referral row, showing this person's code.
  ///
  /// In en, this message translates to:
  /// **'Friends Code: {code}'**
  String profileReferralCode(String code);

  /// Profile screen: notice after the referral code was copied.
  ///
  /// In en, this message translates to:
  /// **'Code copied. Share it with a friend.'**
  String get profileReferralCopied;

  /// Order detail screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailTitle;

  /// Order detail screen: the app-bar heading when there is no such order.
  ///
  /// In en, this message translates to:
  /// **'Order Not Found'**
  String get orderDetailNotFoundTitle;

  /// Order detail screen: shown while the order is being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading this order…'**
  String get orderDetailLoading;

  /// Order detail screen: heading when the order could not be fetched.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order'**
  String get orderDetailLoadFailed;

  /// Order detail screen: line under the load-failed heading.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again — the order itself is safe.'**
  String get orderDetailLoadFailedBody;

  /// Order detail screen: shown when this account has no such order.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderDetailNotFound;

  /// Order detail screen: what a missing order means.
  ///
  /// In en, this message translates to:
  /// **'No order with this number belongs to this account. If you ordered with a different phone number, sign in with that one.'**
  String get orderDetailNotFoundBody;

  /// Order detail screen: button that opens the live tracking page.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get orderDetailTrack;

  /// Order detail screen: heading above the order's id, date and status.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderDetailSectionInfo;

  /// Order detail screen: label of the order number.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderDetailOrderId;

  /// Order detail screen: label of the order date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get orderDetailDate;

  /// Order detail screen: label of the order status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderDetailStatusLabel;

  /// Order detail screen: heading above the delivery details.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get orderDetailSectionAddress;

  /// Order detail screen: label of the receiver's name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get orderDetailName;

  /// Order detail screen: label of the contact number.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get orderDetailPhone;

  /// Order detail screen: label of the delivery address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orderDetailAddress;

  /// Order detail screen: heading above the items bought.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderDetailSectionItems;

  /// Order detail screen: button that opens the delivery-rating dialog.
  ///
  /// In en, this message translates to:
  /// **'Rate Delivery Partner'**
  String get orderDetailRatePartner;

  /// Order detail screen: heading above the bill.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get orderDetailSectionPayment;

  /// Order detail screen: bill row with the items' value.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get orderDetailSubtotal;

  /// Order detail screen: bill row with the delivery charge.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get orderDetailDeliveryFee;

  /// Order detail screen: shown in place of a delivery charge when delivery is free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get orderDetailFree;

  /// Order detail screen: bill row with the wallet money used.
  ///
  /// In en, this message translates to:
  /// **'Wallet Applied'**
  String get orderDetailWalletApplied;

  /// Order detail payment section: the tip line.
  ///
  /// In en, this message translates to:
  /// **'Delivery partner tip'**
  String get orderDetailTip;

  /// Order detail screen: bill row with the final amount.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderDetailTotal;

  /// Order detail screen: button that opens order help.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem / Request Return'**
  String get orderDetailSupport;

  /// Order detail: puts this order's items back in the cart.
  ///
  /// In en, this message translates to:
  /// **'Order again'**
  String get orderDetailOrderAgain;

  /// Order detail: builds the order's bill as a PDF and opens the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Download invoice'**
  String get orderDetailInvoice;

  /// Order detail: the invoice PDF could not be made or shared.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the invoice. Please try again.'**
  String get orderDetailInvoiceFailed;

  /// Order detail: after Order again, how many items went into the cart.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 item added to cart} other{{count} items added to cart}}'**
  String orderDetailOrderAgainAdded(int count);

  /// Order detail: after Order again, how many items could not be added because they are out of stock.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 item is out of stock and was left out} other{{count} items are out of stock and were left out}}'**
  String orderDetailOrderAgainSkipped(int count);

  /// Order detail: Order again found nothing in stock.
  ///
  /// In en, this message translates to:
  /// **'None of these items are in stock right now.'**
  String get orderDetailOrderAgainNone;

  /// Order detail: snackbar action after Order again, opens the cart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get orderDetailViewCart;

  /// Order detail screen: button and confirm button that cancel the order.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get orderDetailCancelOrder;

  /// Order detail screen: status card heading, e.g. Order Confirmed. The status word is translated separately.
  ///
  /// In en, this message translates to:
  /// **'Order {status}'**
  String orderDetailStatusWith(String status);

  /// Order detail screen: first step of the journey.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get orderDetailStepPlaced;

  /// Order detail screen: second step of the journey.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderDetailStepPreparing;

  /// Order detail screen: third step of the journey.
  ///
  /// In en, this message translates to:
  /// **'On Way'**
  String get orderDetailStepOnWay;

  /// Order detail screen: last step of the journey.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDetailStepDelivered;

  /// Order detail screen: how many of an item were bought.
  ///
  /// In en, this message translates to:
  /// **'Qty: {count}'**
  String orderDetailQty(int count);

  /// Order detail screen: button that opens the review dialog for an item.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get orderDetailWriteReview;

  /// Order detail screen: review dialog title, naming the product.
  ///
  /// In en, this message translates to:
  /// **'Review {product}'**
  String orderDetailReviewTitle(String product);

  /// Order detail screen: label of the review note field.
  ///
  /// In en, this message translates to:
  /// **'Share your experience (optional)'**
  String get orderDetailReviewHint;

  /// Order detail screen: button that closes a dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get orderDetailCancel;

  /// Order detail screen: button that saves a dialog's form.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get orderDetailSubmit;

  /// Order detail screen: notice after a review was saved.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review!'**
  String get orderDetailReviewThanks;

  /// Order detail screen: notice when a review could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your review. Please try again.'**
  String get orderDetailReviewFailed;

  /// Order detail screen: title of the delivery-rating dialog.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Delivery Partner'**
  String get orderDetailRateTitle;

  /// Order detail screen: label of the delivery-rating note field.
  ///
  /// In en, this message translates to:
  /// **'Share your delivery experience (optional)'**
  String get orderDetailRateHint;

  /// Order detail screen: notice after a delivery rating was saved.
  ///
  /// In en, this message translates to:
  /// **'Thanks for rating your delivery!'**
  String get orderDetailRateThanks;

  /// Order detail screen: notice when a delivery rating could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your rating. Please try again.'**
  String get orderDetailRateFailed;

  /// Order detail screen: title of the cancel-confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order?'**
  String get orderDetailCancelTitle;

  /// Order detail screen: question in the cancel-confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get orderDetailCancelQuestion;

  /// Order detail screen: button that keeps the order.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get orderDetailNo;

  /// Order detail screen: notice naming the order that was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Order {id} cancelled'**
  String orderDetailCancelled(String id);

  /// Order detail screen: notice when cancelling failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel this order. Please try again.'**
  String get orderDetailCancelFailed;

  /// Product detail screen: the app-bar heading before the product is found.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productDetailTitle;

  /// Product detail screen: shown when the product is no longer listed.
  ///
  /// In en, this message translates to:
  /// **'This product isn\'t available any more.'**
  String get productDetailUnavailable;

  /// Product detail screen: the text handed to the phone's share sheet. The price is already formatted for reading and the app name comes from the app's own constants.
  ///
  /// In en, this message translates to:
  /// **'{name} for {price} on {app}'**
  String productDetailShare(String name, String price, String app);

  /// Product detail screen: badge next to the price showing the discount. The amount is already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'{amount} Saved'**
  String productDetailSaved(String amount);

  /// Product detail screen: notice when the stock alert could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your notification.'**
  String get productDetailNotifyFailed;

  /// Product detail screen: shown when the size/weight options could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the options for this product.'**
  String get productDetailOptionsFailed;

  /// Product detail screen: heading above the size/weight choices.
  ///
  /// In en, this message translates to:
  /// **'Select Option'**
  String get productDetailSelectOption;

  /// Product detail screen: heading of the selling store's card.
  ///
  /// In en, this message translates to:
  /// **'Store Details'**
  String get productDetailStoreDetails;

  /// Product detail screen: how many products the store lists.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 Product} other{{count} Products}}'**
  String productDetailStoreProducts(int count);

  /// Product detail screen: button that opens the store's own page.
  ///
  /// In en, this message translates to:
  /// **'Visit Store'**
  String get productDetailVisitStore;

  /// Product detail screen: what can be done with an order from this store.
  ///
  /// In en, this message translates to:
  /// **'Returnable'**
  String get productDetailReturnable;

  /// Product detail screen: what can be done with an order from this store.
  ///
  /// In en, this message translates to:
  /// **'Cancellable'**
  String get productDetailCancellable;

  /// Product detail screen: the product's category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productDetailCategory;

  /// Product detail screen: the product's brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get productDetailBrand;

  /// Product detail screen: a vegetarian food item.
  ///
  /// In en, this message translates to:
  /// **'Veg'**
  String get productDetailVeg;

  /// Product detail screen: a non-vegetarian food item.
  ///
  /// In en, this message translates to:
  /// **'Non-Veg'**
  String get productDetailNonVeg;

  /// Product detail screen: heading above the plain facts about the item.
  ///
  /// In en, this message translates to:
  /// **'About this Item'**
  String get productDetailAboutItem;

  /// Product detail: heading over the product's details sections, as on Amazon.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productDetailDetailsHeading;

  /// Product detail: section with nutrition lines from the description.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Info'**
  String get productDetailNutrition;

  /// Product detail: open section: key facts table and the About this item points.
  ///
  /// In en, this message translates to:
  /// **'Top highlights'**
  String get productDetailTopHighlights;

  /// Product detail: closed section: every label/value row known about the item.
  ///
  /// In en, this message translates to:
  /// **'Product specifications'**
  String get productDetailProductSpecs;

  /// Product detail: closed section: the description's prose.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get productDetailAdditionalDetails;

  /// Product detail: always-shown section with ingredients and the disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Important information'**
  String get productDetailImportantInfo;

  /// Product detail: label over what the product is made of.
  ///
  /// In en, this message translates to:
  /// **'Ingredients:'**
  String get productDetailIngredients;

  /// Product detail: label over the packaging disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Legal Disclaimer:'**
  String get productDetailLegalDisclaimer;

  /// Product detail: the disclaimer under Important information.
  ///
  /// In en, this message translates to:
  /// **'Actual product packaging and materials may carry more or different information than what is shown here. Please read the labels, warnings and directions before using or consuming a product.'**
  String get productDetailLegalDisclaimerBody;

  /// Product detail: table label for the pack size.
  ///
  /// In en, this message translates to:
  /// **'Net Quantity'**
  String get productDetailNetQuantity;

  /// Product detail: table label for vegetarian or not.
  ///
  /// In en, this message translates to:
  /// **'Diet Type'**
  String get productDetailDietType;

  /// Product detail: table label for the seller's store.
  ///
  /// In en, this message translates to:
  /// **'Sold by'**
  String get productDetailSoldByLabel;

  /// Product detail: line with the green veg mark.
  ///
  /// In en, this message translates to:
  /// **'This is a Vegetarian product.'**
  String get productDetailVegProduct;

  /// Product detail: line with the red non-veg mark.
  ///
  /// In en, this message translates to:
  /// **'This is a Non-Vegetarian product.'**
  String get productDetailNonVegProduct;

  /// Product detail: shows the rest of the About this item points.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get productDetailSeeMore;

  /// Product detail: hides the extra About this item points again.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get productDetailSeeLess;

  /// Product detail screen: button that asks to be told when the item is back.
  ///
  /// In en, this message translates to:
  /// **'Notify me when available'**
  String get productDetailNotifyMe;

  /// Product detail screen: the same button once the person is on the list.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you'**
  String get productDetailNotifyOn;

  /// Product detail screen: the buy bar's button.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productDetailAddToCart;

  /// Product detail screen: the buy bar's button once the item is in the cart.
  ///
  /// In en, this message translates to:
  /// **'Go to Cart'**
  String get productDetailGoToCart;

  /// Product detail screen: heading above the customer reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get productDetailReviews;

  /// Product detail screen: shown when the reviews could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the reviews.'**
  String get productDetailReviewsFailed;

  /// Product detail screen: shown when the product has no reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet for this product.'**
  String get productDetailNoReviews;

  /// Product detail screen: heading above the other products by this store.
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get productDetailSimilar;

  /// Product detail screen: the admin-only bar, meaning customers can still see it.
  ///
  /// In en, this message translates to:
  /// **'Admin — this product is on sale'**
  String get productDetailAdminOnSale;

  /// Product detail screen: admin button that takes the product off the store.
  ///
  /// In en, this message translates to:
  /// **'Hide from store'**
  String get productDetailHideFromStore;

  /// Product detail screen: title of the admin's hide confirmation, naming the product.
  ///
  /// In en, this message translates to:
  /// **'Hide \"{name}\"?'**
  String productDetailHideTitle(String name);

  /// Product detail screen: what hiding does.
  ///
  /// In en, this message translates to:
  /// **'Customers will no longer see it. The seller keeps the product and can show it again.'**
  String get productDetailHideBody;

  /// Product detail screen: button that closes a dialog without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get productDetailCancel;

  /// Product detail screen: button that hides the product.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get productDetailHide;

  /// Product detail screen: notice when hiding failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t hide this product.'**
  String get productDetailHideFailed;

  /// Checkout screen: paying by UPI.
  ///
  /// In en, this message translates to:
  /// **'UPI / GPay / PhonePe'**
  String get checkoutPayUpi;

  /// Checkout screen: paying by card.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get checkoutPayCard;

  /// Checkout screen: paying on delivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get checkoutPayCod;

  /// Checkout screen: the coupon does not exist.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon code'**
  String get checkoutCouponInvalid;

  /// Checkout screen: the coupon's minimum order is not met. The amount is already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'Minimum order of {amount} required'**
  String checkoutCouponMinOrder(String amount);

  /// Checkout screen: the coupon could not be checked (network).
  ///
  /// In en, this message translates to:
  /// **'Could not apply coupon'**
  String get checkoutCouponFailed;

  /// Checkout screen: the coupon that is now on the order.
  ///
  /// In en, this message translates to:
  /// **'Coupon \"{code}\" applied'**
  String checkoutCouponApplied(String code);

  /// Checkout screen: notice when the delivery fields are incomplete.
  ///
  /// In en, this message translates to:
  /// **'Please fill all details'**
  String get checkoutFillDetails;

  /// Checkout screen: notice when the cart could not be sent to the server.
  ///
  /// In en, this message translates to:
  /// **'Could not update your cart. Check your connection and try again.'**
  String get checkoutCartSyncFailed;

  /// Checkout screen: notice when the payment failed and gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Payment failed.'**
  String get checkoutPaymentFailed;

  /// Checkout screen: the worst case — money taken, no order. The payment id is what support needs.
  ///
  /// In en, this message translates to:
  /// **'Payment succeeded but the order could not be placed. Contact support with payment ID {paymentId}.'**
  String checkoutPaidOrderFailed(String paymentId);

  /// Checkout screen: notice when placing the order failed and gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Could not place order. Please try again.'**
  String get checkoutPlaceFailed;

  /// Checkout screen: the server charged more than promised because the coupon was refused. The amount is already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'Final total {total} — this coupon could not be applied to the order (a coupon can only be used once per account).'**
  String checkoutFinalTotalCoupon(String total);

  /// Checkout screen: the server charged a different amount than the screen promised. Both amounts are already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'Final total {total}, not {promised} as shown before payment.'**
  String checkoutFinalTotalChanged(String total, String promised);

  /// Checkout screen: label of the receiver's name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get checkoutFullName;

  /// Checkout screen: label of the contact number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get checkoutPhoneNumber;

  /// Checkout: section title for notes to the delivery partner.
  ///
  /// In en, this message translates to:
  /// **'Delivery instructions'**
  String get checkoutInstructions;

  /// Checkout: section title for the optional tip.
  ///
  /// In en, this message translates to:
  /// **'Tip your delivery partner'**
  String get checkoutTipTitle;

  /// Checkout: under the tip title — the store keeps none of it.
  ///
  /// In en, this message translates to:
  /// **'Your whole tip goes to the delivery partner.'**
  String get checkoutTipBody;

  /// Checkout order summary: the tip line.
  ///
  /// In en, this message translates to:
  /// **'Delivery partner tip'**
  String get checkoutTipLine;

  /// Checkout: hint in the free-text delivery note field.
  ///
  /// In en, this message translates to:
  /// **'Anything else for the delivery partner (optional)'**
  String get checkoutInstructionsHint;

  /// Checkout: quick delivery instruction chip.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ring the bell'**
  String get checkoutNoteNoBell;

  /// Checkout: quick delivery instruction chip.
  ///
  /// In en, this message translates to:
  /// **'Leave at the door'**
  String get checkoutNoteLeaveDoor;

  /// Checkout: quick delivery instruction chip.
  ///
  /// In en, this message translates to:
  /// **'Call when you arrive'**
  String get checkoutNoteCallArrive;

  /// Checkout: quick delivery instruction chip.
  ///
  /// In en, this message translates to:
  /// **'Pet at home'**
  String get checkoutNotePet;

  /// Checkout screen: hint inside the coupon field.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get checkoutCouponHint;

  /// Checkout screen: button that checks the coupon.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get checkoutApply;

  /// Checkout screen: one line of the bill, naming the item and how many.
  ///
  /// In en, this message translates to:
  /// **'{name} × {count}'**
  String checkoutItemLine(String name, int count);

  /// Checkout screen: bill row with the coupon's saving.
  ///
  /// In en, this message translates to:
  /// **'Coupon Discount'**
  String get checkoutCouponDiscount;

  /// Checkout screen: the wallet switch, with the balance available. The amount is a plain number.
  ///
  /// In en, this message translates to:
  /// **'Use wallet balance (₹{amount} available)'**
  String checkoutUseWallet(String amount);

  /// Checkout screen: bill row with the wallet money used.
  ///
  /// In en, this message translates to:
  /// **'Wallet Used'**
  String get checkoutWalletUsed;

  /// Checkout screen: the button that pays and places the order.
  ///
  /// In en, this message translates to:
  /// **'PLACE ORDER'**
  String get checkoutPlaceOrder;

  /// Checkout screen: heading above the saved addresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get checkoutSavedAddresses;

  /// Checkout screen: badge on the default address.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get checkoutDefaultBadge;

  /// Confirmation screen: the app-bar heading.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get checkoutOrderPlacedTitle;

  /// Confirmation screen: the good news.
  ///
  /// In en, this message translates to:
  /// **'Order Placed Successfully!'**
  String get checkoutSuccess;

  /// Confirmation screen: the order's number.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String checkoutOrderId(String id);

  /// Confirmation screen: where the order is going.
  ///
  /// In en, this message translates to:
  /// **'Delivering to: {address}'**
  String checkoutDeliveringTo(String address);

  /// Confirmation screen: when the order is expected.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery: {eta}'**
  String checkoutExpectedDelivery(String eta);

  /// Confirmation screen: used in place of a delivery estimate when there is none.
  ///
  /// In en, this message translates to:
  /// **'shown once your address is set'**
  String get checkoutEtaUnknown;

  /// Confirmation screen: what the order cost. The amount is already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String checkoutTotal(String amount);

  /// Confirmation screen: button that goes back to the store.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get checkoutContinue;

  /// Home header: the promo card's headline.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get homeFreeDelivery;

  /// Home header: the promo card's line. The amount is already formatted for reading.
  ///
  /// In en, this message translates to:
  /// **'on orders above {amount}'**
  String homeFreeDeliveryAbove(String amount);

  /// Home header: the delivery-time line when an address is set.
  ///
  /// In en, this message translates to:
  /// **'Delivery in'**
  String get homeEtaDeliveryIn;

  /// Home header: the delivery-time line before an address is set.
  ///
  /// In en, this message translates to:
  /// **'Delivery time'**
  String get homeEtaDeliveryTime;

  /// Home header: asks for an address so the time can be worked out.
  ///
  /// In en, this message translates to:
  /// **'Set your address'**
  String get homeEtaSetAddress;

  /// Home header: used when there is no time to quote.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get homeEtaDelivery;

  /// Home header: there is no nearest store, but stores nearby can deliver.
  ///
  /// In en, this message translates to:
  /// **'From local stores'**
  String get homeEtaFromLocal;

  /// Home header: names the store the address is outside of.
  ///
  /// In en, this message translates to:
  /// **'Nearest store: {store}'**
  String homeEtaNearestStore(String store);

  /// Home header: the address is outside every store's range.
  ///
  /// In en, this message translates to:
  /// **'Outside delivery area'**
  String get homeEtaOutOfRange;

  /// Home header: the address row when none is saved.
  ///
  /// In en, this message translates to:
  /// **'Tap to set your delivery address'**
  String get homeAddressHint;

  /// Home search bar: what the field says before examples are known.
  ///
  /// In en, this message translates to:
  /// **'Search for products'**
  String get homeSearchProducts;

  /// Home search bar: examples taken from what is really in the store.
  ///
  /// In en, this message translates to:
  /// **'Search for {names}…'**
  String homeSearchFor(String names);

  /// Home chip strip: the chip that opens the category list.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// Home promo card: the action when a banner names none of its own.
  ///
  /// In en, this message translates to:
  /// **'Shop now'**
  String get homeShopNow;

  /// Home grid: how many products the current filter matched.
  ///
  /// In en, this message translates to:
  /// **'{count} products found'**
  String homeProductsFound(int count);

  /// Home grid: heading when the products could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load products'**
  String get homeLoadFailed;

  /// Home grid: heading when the filter matched nothing.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get homeNoProducts;

  /// Home grid: line under the load-failed heading.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get homeLoadFailedBody;

  /// Home grid: line under the empty heading.
  ///
  /// In en, this message translates to:
  /// **'Try another category or search.'**
  String get homeNoProductsBody;

  /// Home grid: button that loads the products again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeRetry;

  /// Home All tab: heading of the shelf of products on offer.
  ///
  /// In en, this message translates to:
  /// **'Deals worth grabbing'**
  String get homeDealsHeading;

  /// Home: heading of the shelf of products from the customer's past orders.
  ///
  /// In en, this message translates to:
  /// **'Buy again'**
  String get homeBuyAgain;

  /// Home: line under the Buy again heading.
  ///
  /// In en, this message translates to:
  /// **'From your past orders'**
  String get homeBuyAgainSub;

  /// Home All tab: heading of the best-selling shelf.
  ///
  /// In en, this message translates to:
  /// **'Bestsellers'**
  String get homeBestsellersHeading;

  /// Home All tab: badge on a collage card that stands for several products.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String homeMoreCount(int count);

  /// Home All tab: the row that opens the full product list.
  ///
  /// In en, this message translates to:
  /// **'See all products'**
  String get homeSeeAllProducts;

  /// Home: heading of the brands strip.
  ///
  /// In en, this message translates to:
  /// **'Shop by Brand'**
  String get homeBrandsTitle;

  /// Home: line under the brands heading.
  ///
  /// In en, this message translates to:
  /// **'Your favourite brands, all in one place.'**
  String get homeBrandsSubtitle;

  /// Home: heading of the local-stores strip.
  ///
  /// In en, this message translates to:
  /// **'Local Brands'**
  String get homeLocalBrandsTitle;

  /// Home: line under the local-stores heading.
  ///
  /// In en, this message translates to:
  /// **'Shop direct from businesses in your area.'**
  String get homeLocalBrandsSubtitle;

  /// Home: how many products a brand lists.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 product} other{{count} products}}'**
  String homeProductCount(int count);

  /// Home: how many items a store lists.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 item} other{{count} items}}'**
  String homeItemCount(int count);

  /// Home: used in place of a store's name when it has none.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get homeStoreFallback;

  /// Home: a store that is open right now.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeOpen;

  /// Home: a store that is closed right now.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get homeClosed;

  /// Addresses: toast after a new address is saved.
  ///
  /// In en, this message translates to:
  /// **'Address added'**
  String get addressAdded;

  /// Addresses: toast after an edit is saved.
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressUpdated;

  /// Addresses: toast when the default could not be switched.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the default address.'**
  String get addressDefaultFailed;

  /// Addresses: heading of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete address?'**
  String get addressDeleteTitle;

  /// Addresses: cancel the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get addressCancel;

  /// Addresses: confirm/execute a delete; also the bin icon tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addressDelete;

  /// Addresses: toast when a delete failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete that address.'**
  String get addressDeleteFailed;

  /// Addresses: screen title, the saved-address list.
  ///
  /// In en, this message translates to:
  /// **'Delivery Addresses'**
  String get addressTitle;

  /// Addresses: empty list headline.
  ///
  /// In en, this message translates to:
  /// **'No addresses yet'**
  String get addressEmptyTitle;

  /// Addresses: empty list body.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address — type it, use your live location, or pick it on the map.'**
  String get addressEmptyBody;

  /// Addresses: button on the empty state.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addressAdd;

  /// Addresses: button under the saved list.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addressAddNew;

  /// Addresses: badge on the default address card.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get addressDefaultBadge;

  /// Addresses: edit button on an address card.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get addressEdit;

  /// Addresses: make this card the default one.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get addressSetDefault;

  /// Addresses: the Home label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// Addresses: the Work label.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addressLabelWork;

  /// Addresses: the catch-all address label.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressLabelOther;

  /// Addresses: label used for an address taken from live location.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get addressLabelCurrent;

  /// Address form: title when creating.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addressFormAddTitle;

  /// Address form: title when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get addressFormEditTitle;

  /// Address form: reverse geocoding came back empty.
  ///
  /// In en, this message translates to:
  /// **'Got your location, but couldn\'t find the address. Please type it in.'**
  String get addressLocateFailed;

  /// Address form: snackbar action that opens the app settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get addressSettings;

  /// Address form / sheet: title of the map picker.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get addressPickTitle;

  /// Address form / sheet: search field inside the map picker.
  ///
  /// In en, this message translates to:
  /// **'Search area, street or pincode'**
  String get addressPickHint;

  /// Address form: confirm button in the map picker.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get addressConfirmLocation;

  /// Address sheet: confirm button in the map picker.
  ///
  /// In en, this message translates to:
  /// **'Deliver here'**
  String get addressDeliverHere;

  /// Addresses: toast when saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the address. Please try again.'**
  String get addressSaveFailed;

  /// Address sheet: toast when picking a saved address failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the address.'**
  String get addressChangeFailed;

  /// Address form / sheet: live-location option.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get addressUseCurrent;

  /// Address form / sheet: map option.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get addressChooseMap;

  /// Address sheet: under the live-location option.
  ///
  /// In en, this message translates to:
  /// **'Find where you are right now'**
  String get addressFindWhere;

  /// Address sheet: under the map option.
  ///
  /// In en, this message translates to:
  /// **'Search or drag the pin'**
  String get addressDragPin;

  /// Address sheet: option that opens the address form.
  ///
  /// In en, this message translates to:
  /// **'Add address manually'**
  String get addressAddManually;

  /// Address sheet: under the manual-address option.
  ///
  /// In en, this message translates to:
  /// **'Type your full address'**
  String get addressTypeFull;

  /// Address sheet: heading above the saved list.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get addressSavedHeading;

  /// Address sheet: heading when only a typed address exists.
  ///
  /// In en, this message translates to:
  /// **'Current delivery address'**
  String get addressCurrentHeading;

  /// Address sheet: sheet title.
  ///
  /// In en, this message translates to:
  /// **'Choose delivery address'**
  String get addressChooseTitle;

  /// Address sheet / form: address used when reverse geocoding fails.
  ///
  /// In en, this message translates to:
  /// **'Current location ({coords})'**
  String addressCurrentFallback(String coords);

  /// Address sheet: address used when the picked pin has no address.
  ///
  /// In en, this message translates to:
  /// **'Pinned location ({coords})'**
  String addressPinnedFallback(String coords);

  /// Address sheet: toast confirming the new delivery address.
  ///
  /// In en, this message translates to:
  /// **'Delivering to {address}'**
  String addressDeliveringTo(String address);

  /// Address form: chip showing the chosen map point.
  ///
  /// In en, this message translates to:
  /// **'Map location set  •  {coords}'**
  String addressMapSet(String coords);

  /// Address form: heading above the Home/Work/Other chips.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get addressSaveAs;

  /// Address form: label of the address field.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get addressFullLabel;

  /// Address form: hint inside the address field.
  ///
  /// In en, this message translates to:
  /// **'House / flat no., building, street, area, city, pincode'**
  String get addressFullHint;

  /// Address form: validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter your full address'**
  String get addressFullError;

  /// Address form: save button when editing.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get addressSaveChanges;

  /// Address form: save button when creating.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get addressSaveAddress;

  /// KYC: screen title.
  ///
  /// In en, this message translates to:
  /// **'KYC Documents'**
  String get kycTitle;

  /// KYC: error state headline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your documents'**
  String get kycLoadFailed;

  /// KYC: toast when an upload failed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload this document.'**
  String get kycUploadFailed;

  /// KYC: document waiting for review.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get kycStatusPending;

  /// KYC: document approved.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get kycStatusVerified;

  /// KYC: document turned down.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get kycStatusRejected;

  /// KYC: button on a document that is not uploaded yet.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get kycUpload;

  /// KYC: button on a document that is already uploaded.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get kycReplace;

  /// KYC: name of the PAN document.
  ///
  /// In en, this message translates to:
  /// **'PAN Card'**
  String get kycDocPan;

  /// KYC: name of the GST document.
  ///
  /// In en, this message translates to:
  /// **'GST Certificate'**
  String get kycDocGst;

  /// KYC: name of the FSSAI document.
  ///
  /// In en, this message translates to:
  /// **'FSSAI License'**
  String get kycDocFssai;

  /// KYC: name of the bank-proof document.
  ///
  /// In en, this message translates to:
  /// **'Bank Proof'**
  String get kycDocBankProof;

  /// KYC: name of the address-proof document.
  ///
  /// In en, this message translates to:
  /// **'Address Proof'**
  String get kycDocAddressProof;

  /// Store page: empty shelf message.
  ///
  /// In en, this message translates to:
  /// **'This store has no products yet'**
  String get storeNoProducts;

  /// Store page: the store is open right now.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get storeStatusOpen;

  /// Store page: the store is closed right now.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get storeStatusClosed;

  /// Search: picker failed to open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera or gallery.'**
  String get searchCameraFailed;

  /// Search: the on-device model was not available.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this photo — the scanner needs a one-time download, so check your internet connection and try again.'**
  String get searchScannerFailed;

  /// Search: photo read fine but nothing matched.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t match this photo to a product. Try a clearer picture, or type the name.'**
  String get searchNoMatch;

  /// Search: hint while the photo is being read.
  ///
  /// In en, this message translates to:
  /// **'Reading your photo…'**
  String get searchReading;

  /// Search: field hint.
  ///
  /// In en, this message translates to:
  /// **'Search products, brands, stores…'**
  String get searchHint;

  /// Search: clear-button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// Search: voice/photo button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Search by voice or photo'**
  String get searchByVoiceOrPhoto;

  /// Search: how many results the query returned.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 result found} other{{count} results found}}'**
  String searchResultsFound(int count);

  /// Search: empty state headline.
  ///
  /// In en, this message translates to:
  /// **'Search for products, brands or stores'**
  String get searchIdleTitle;

  /// Search: heading above the suggestion chips.
  ///
  /// In en, this message translates to:
  /// **'Try searching for'**
  String get searchTrySearching;

  /// Search: nothing matched the query.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResultsTitle(String query);

  /// Search: line under the no-results headline.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling or try something else.'**
  String get searchNoResultsBody;

  /// Search: heading above the closest-match suggestion chips shown on a zero-result search.
  ///
  /// In en, this message translates to:
  /// **'Did you mean:'**
  String get searchDidYouMean;

  /// Search: heading above the shopper's own past searches, on the idle screen.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// Search: button that erases the recent-searches list.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearRecent;

  /// Edit tools: back out of a dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editCancel;

  /// Edit tools: accept a text dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editSave;

  /// Edit tools: toast while an upload runs.
  ///
  /// In en, this message translates to:
  /// **'Uploading the picture…'**
  String get editUploading;

  /// Edit tools: upload failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the picture. Try again.'**
  String get editUploadFailed;

  /// Edit tools: a change could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Check your connection and try again.'**
  String get editSaveFailed;

  /// Edit tools: switch-off failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that.'**
  String get editSaveFailedShort;

  /// Edit tools: page-banner change failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Try again.'**
  String get editSaveRetry;

  /// Edit tools: the card moved one place.
  ///
  /// In en, this message translates to:
  /// **'Moved.'**
  String get editMoved;

  /// Edit tools: cannot move up any further.
  ///
  /// In en, this message translates to:
  /// **'Already the first.'**
  String get editAlreadyFirst;

  /// Edit tools: cannot move down any further.
  ///
  /// In en, this message translates to:
  /// **'Already the last.'**
  String get editAlreadyLast;

  /// Edit tools: swap the card art for a photo.
  ///
  /// In en, this message translates to:
  /// **'Replace this card'**
  String get editReplaceCard;

  /// Edit tools: under Replace this card.
  ///
  /// In en, this message translates to:
  /// **'The card becomes the photo you pick'**
  String get editReplaceCardHint;

  /// Edit tools: card art replaced.
  ///
  /// In en, this message translates to:
  /// **'Card replaced.'**
  String get editCardReplaced;

  /// Edit tools: drop the photo card.
  ///
  /// In en, this message translates to:
  /// **'Back to the normal card'**
  String get editBackToNormalCard;

  /// Edit tools: under Back to the normal card.
  ///
  /// In en, this message translates to:
  /// **'Drops the photo card'**
  String get editBackToNormalCardHint;

  /// Edit tools: photo card dropped.
  ///
  /// In en, this message translates to:
  /// **'Back to the normal card.'**
  String get editBackToNormalCardDone;

  /// Edit tools: change a card or banner picture.
  ///
  /// In en, this message translates to:
  /// **'Change picture'**
  String get editChangePicture;

  /// Edit tools: under Change picture for a card.
  ///
  /// In en, this message translates to:
  /// **'Only the photo inside the card'**
  String get editChangePictureHint;

  /// Edit tools: under Change picture for a banner.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo from your gallery'**
  String get editPickPhotoHint;

  /// Edit tools: picture replaced.
  ///
  /// In en, this message translates to:
  /// **'Picture changed.'**
  String get editPictureChanged;

  /// Edit tools: bring back the product photo.
  ///
  /// In en, this message translates to:
  /// **'Show the picture again'**
  String get editShowPictureAgain;

  /// Edit tools: under Show the picture again.
  ///
  /// In en, this message translates to:
  /// **'Back to the product\'s photo'**
  String get editShowPictureAgainHint;

  /// Edit tools: the product photo is shown again.
  ///
  /// In en, this message translates to:
  /// **'Picture is back.'**
  String get editPictureIsBack;

  /// Edit tools: drop the custom picture.
  ///
  /// In en, this message translates to:
  /// **'Use a product photo again'**
  String get editUseProductPhoto;

  /// Edit tools: under Use a product photo again.
  ///
  /// In en, this message translates to:
  /// **'Drops the picture you set'**
  String get editUseProductPhotoHint;

  /// Edit tools: custom picture dropped.
  ///
  /// In en, this message translates to:
  /// **'Back to the product photo.'**
  String get editBackToProductPhoto;

  /// Edit tools: card with text only.
  ///
  /// In en, this message translates to:
  /// **'Remove picture'**
  String get editRemovePicture;

  /// Edit tools: under Remove picture.
  ///
  /// In en, this message translates to:
  /// **'The card shows no photo, only its text'**
  String get editRemovePictureHint;

  /// Edit tools: picture removed.
  ///
  /// In en, this message translates to:
  /// **'Picture removed.'**
  String get editPictureRemoved;

  /// Edit tools: rename a chip.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get editChangeName;

  /// Edit tools: title of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editNameTitle;

  /// Edit tools: note under the rename field.
  ///
  /// In en, this message translates to:
  /// **'A chip\'s page look follows its name, so renaming chips like Electronics or Kids changes how their page looks.'**
  String get editNameNote;

  /// Edit tools: rename saved.
  ///
  /// In en, this message translates to:
  /// **'Name changed.'**
  String get editNameChanged;

  /// Edit tools: take a card off the store.
  ///
  /// In en, this message translates to:
  /// **'Hide from store'**
  String get editHideFromStore;

  /// Edit tools: put it back.
  ///
  /// In en, this message translates to:
  /// **'Show in store'**
  String get editShowInStore;

  /// Edit tools: the card is hidden now.
  ///
  /// In en, this message translates to:
  /// **'Hidden.'**
  String get editHidden;

  /// Edit tools: the card is visible again.
  ///
  /// In en, this message translates to:
  /// **'Shown.'**
  String get editShown;

  /// Edit tools: add a card inside a chip.
  ///
  /// In en, this message translates to:
  /// **'Add a sub-category'**
  String get editAddSubCategory;

  /// Edit tools: under Add a sub-category.
  ///
  /// In en, this message translates to:
  /// **'A new card inside this chip'**
  String get editAddSubCategoryHint;

  /// Edit tools: title of the new sub-category dialog.
  ///
  /// In en, this message translates to:
  /// **'New sub-category'**
  String get editNewSubCategory;

  /// Edit tools: the new sub-category is in.
  ///
  /// In en, this message translates to:
  /// **'Added.'**
  String get editAdded;

  /// Edit tools: move a chip one place up.
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get editMoveEarlier;

  /// Edit tools: move a sub-category up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get editMoveUp;

  /// Edit tools: move a chip one place down.
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get editMoveLater;

  /// Edit tools: move a sub-category down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get editMoveDown;

  /// Edit tools: delete a card.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get editDelete;

  /// Edit tools: a chip with cards inside cannot go.
  ///
  /// In en, this message translates to:
  /// **'Remove its sub-categories first.'**
  String get editRemoveSubsFirst;

  /// Edit tools: a chip holding products cannot go.
  ///
  /// In en, this message translates to:
  /// **'Products are in \"{name}\". Move them, or just hide it.'**
  String editProductsAreIn(String name);

  /// Edit tools: delete confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String editDeleteNamed(String name);

  /// Edit tools: delete confirmation body.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get editCannotUndo;

  /// Edit tools: the card is gone.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get editDeleted;

  /// Edit tools: open the product editor the seller uses.
  ///
  /// In en, this message translates to:
  /// **'Edit photos & details'**
  String get editEditPhotosDetails;

  /// Edit tools: under Edit photos & details.
  ///
  /// In en, this message translates to:
  /// **'The same screen the seller uses'**
  String get editEditPhotosDetailsHint;

  /// Edit tools: see the product as a customer does.
  ///
  /// In en, this message translates to:
  /// **'Open product page'**
  String get editOpenProductPage;

  /// Edit tools: under Hide from store for a product.
  ///
  /// In en, this message translates to:
  /// **'The seller keeps it and can show it again'**
  String get editKeepVisibleHint;

  /// Edit tools: hide confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Hide \"{name}\"?'**
  String editHideNamed(String name);

  /// Edit tools: hide confirmation body.
  ///
  /// In en, this message translates to:
  /// **'Customers will no longer see it.'**
  String get editHideNamedBody;

  /// Edit tools: confirm hiding.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get editHide;

  /// Edit tools: hiding a product failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t hide this product.'**
  String get editHideFailed;

  /// Edit tools: a banner that opens nowhere.
  ///
  /// In en, this message translates to:
  /// **'Nothing — just a picture'**
  String get editNothingJustPicture;

  /// Edit tools: heading of the link-target sheet.
  ///
  /// In en, this message translates to:
  /// **'Where should it open?'**
  String get editWhereOpen;

  /// Edit tools: edit the words on a banner.
  ///
  /// In en, this message translates to:
  /// **'Change text'**
  String get editChangeText;

  /// Edit tools: under Change text.
  ///
  /// In en, this message translates to:
  /// **'Heading, the line under it and the button'**
  String get editChangeTextHint;

  /// Edit tools: title of the heading dialog.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get editHeadingTitle;

  /// Edit tools: title of the subtitle dialog.
  ///
  /// In en, this message translates to:
  /// **'Line under the heading'**
  String get editSubtitleTitle;

  /// Edit tools: title of the button-label dialog.
  ///
  /// In en, this message translates to:
  /// **'Button text'**
  String get editButtonTextTitle;

  /// Edit tools: banner text saved.
  ///
  /// In en, this message translates to:
  /// **'Text changed.'**
  String get editTextChanged;

  /// Edit tools: change where a banner links to.
  ///
  /// In en, this message translates to:
  /// **'Change where it opens'**
  String get editChangeWhereOpens;

  /// Edit tools: a change is in.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get editSaved;

  /// Edit tools: open the banners screen.
  ///
  /// In en, this message translates to:
  /// **'Add a new banner'**
  String get editAddNewBanner;

  /// Edit tools: under Add a new banner.
  ///
  /// In en, this message translates to:
  /// **'Opens all banners'**
  String get editAddNewBannerHint;

  /// Edit tools: take a banner off the home page.
  ///
  /// In en, this message translates to:
  /// **'Hide this banner'**
  String get editHideThisBanner;

  /// Edit tools: remove a banner.
  ///
  /// In en, this message translates to:
  /// **'Delete this banner'**
  String get editDeleteThisBanner;

  /// Edit tools: banner delete confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete this banner?'**
  String get editDeleteThisBannerQ;

  /// Edit tools: sheet title for a stand-in banner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get editBannerTitle;

  /// Edit tools: open the festival editor.
  ///
  /// In en, this message translates to:
  /// **'Edit name, dates & colours'**
  String get editEditNameDates;

  /// Edit tools: take a festival off the home page.
  ///
  /// In en, this message translates to:
  /// **'Switch this festival off'**
  String get editSwitchFestivalOff;

  /// Edit tools: under Switch this festival off.
  ///
  /// In en, this message translates to:
  /// **'Home goes back to the plain Festival chip'**
  String get editSwitchFestivalOffHint;

  /// Edit tools: the festival is off.
  ///
  /// In en, this message translates to:
  /// **'Off.'**
  String get editOff;

  /// Edit tools: open the festivals screen.
  ///
  /// In en, this message translates to:
  /// **'All festivals'**
  String get editAllFestivals;

  /// Edit tools: under All festivals.
  ///
  /// In en, this message translates to:
  /// **'Add a new one, or change dates'**
  String get editAllFestivalsHint;

  /// Edit tools: change the picture across a chip page.
  ///
  /// In en, this message translates to:
  /// **'Change banner'**
  String get editChangeBanner;

  /// Edit tools: under Change banner.
  ///
  /// In en, this message translates to:
  /// **'The picture across the top of the {chip} page'**
  String editChangeBannerHint(String chip);

  /// Edit tools: the page banner was replaced.
  ///
  /// In en, this message translates to:
  /// **'Banner changed.'**
  String get editBannerChanged;

  /// Edit tools: drop the page banner.
  ///
  /// In en, this message translates to:
  /// **'Remove the banner'**
  String get editRemoveTheBanner;

  /// Edit tools: under Remove the banner.
  ///
  /// In en, this message translates to:
  /// **'Back to the title and artwork'**
  String get editRemoveTheBannerHint;

  /// Edit tools: the page banner is gone.
  ///
  /// In en, this message translates to:
  /// **'Banner removed.'**
  String get editBannerRemoved;

  /// Edit mode: sheet heading, the card name after the dot.
  ///
  /// In en, this message translates to:
  /// **'Edit · {title}'**
  String editSheetTitle(String title);

  /// Edit mode: a card with no tools.
  ///
  /// In en, this message translates to:
  /// **'Nothing to edit here.'**
  String get editNothingToEdit;

  /// Edit mode: the switch while it is on.
  ///
  /// In en, this message translates to:
  /// **'Editing — tap to finish'**
  String get editModeOn;

  /// Edit mode: the switch while it is off.
  ///
  /// In en, this message translates to:
  /// **'Edit mode'**
  String get editModeOff;

  /// Chip page: heading of the sub-category tiles.
  ///
  /// In en, this message translates to:
  /// **'Shop by category'**
  String get chipShopByCategory;

  /// Chip page: shelf heading for the discounted picks.
  ///
  /// In en, this message translates to:
  /// **'Top Deals'**
  String get chipTopDeals;

  /// Chip page: shelf heading for the gifting layout.
  ///
  /// In en, this message translates to:
  /// **'Top buys'**
  String get chipTopBuys;

  /// Chip page: shelf heading for the picks.
  ///
  /// In en, this message translates to:
  /// **'Top picks'**
  String get chipTopPicks;

  /// Chip page: tag over a featured card.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get chipFeatured;

  /// Chip page: tag over a deal card.
  ///
  /// In en, this message translates to:
  /// **'Up to {percent}% OFF'**
  String chipUpToOff(int percent);

  /// Chip page: small line above the Pharmacy title.
  ///
  /// In en, this message translates to:
  /// **'HEALTH & WELLNESS'**
  String get chipHeroPharmacyKicker;

  /// Chip page: Pharmacy title.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy essentials'**
  String get chipHeroPharmacyTitle;

  /// Chip page: small line above the Kids title.
  ///
  /// In en, this message translates to:
  /// **'TINY TOTS'**
  String get chipHeroKidsKicker;

  /// Chip page: Kids title.
  ///
  /// In en, this message translates to:
  /// **'ZONE'**
  String get chipHeroKidsTitle;

  /// Chip page: small line above the Decor title.
  ///
  /// In en, this message translates to:
  /// **'REIMAGINE'**
  String get chipHeroDecorKicker;

  /// Chip page: Decor title.
  ///
  /// In en, this message translates to:
  /// **'your space'**
  String get chipHeroDecorTitle;

  /// Chip page: small line above the Imported title.
  ///
  /// In en, this message translates to:
  /// **'IMPORTED STORE'**
  String get chipHeroImportedKicker;

  /// Chip page: Imported title.
  ///
  /// In en, this message translates to:
  /// **'Global favourites'**
  String get chipHeroImportedTitle;

  /// Chip page: line under the Imported title.
  ///
  /// In en, this message translates to:
  /// **'Discover brands from across the world'**
  String get chipHeroImportedSubtitle;

  /// Tracking screen: title.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackingTitle;

  /// Tracking screen: error headline.
  ///
  /// In en, this message translates to:
  /// **'Tracking Not Found'**
  String get trackingNotFound;

  /// Tracking screen: error line.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get trackingOrderMissing;

  /// Tracking screen: heading with the order id.
  ///
  /// In en, this message translates to:
  /// **'Order {id}'**
  String trackingOrderNumber(String id);

  /// Tracking screen: when it should arrive.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery: {eta}'**
  String trackingExpected(String eta);

  /// Tracking screen: heading of the items list.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get trackingSummary;

  /// Tracking screen: total row.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get trackingTotal;

  /// Tracking screen: first status step.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get trackingPlaced;

  /// Tracking screen: second status step.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get trackingPreparing;

  /// Tracking screen: third status step.
  ///
  /// In en, this message translates to:
  /// **'On Way'**
  String get trackingOnWay;

  /// Tracking screen: last status step.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get trackingDelivered;

  /// Tracking screen: current-step tag.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get trackingInProgress;

  /// Tracking screen: shown until the partner position arrives.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the delivery partner\'s location…'**
  String get trackingWaitingLocation;

  /// Tracking: under the delivery partner's name.
  ///
  /// In en, this message translates to:
  /// **'is on the way with your order'**
  String get trackingRiderOnWay;

  /// Tracking: the delivery partner's name when it could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Your delivery partner'**
  String get trackingRiderFallback;

  /// Tracking: button to phone the delivery partner.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get trackingCallRider;

  /// Tracking: the phone app could not be opened to call the partner.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the dialler.'**
  String get trackingCallFailed;

  /// Tracking map: the rider's position arrived in the last few seconds.
  ///
  /// In en, this message translates to:
  /// **'Live · just now'**
  String get trackingLiveNow;

  /// Tracking map: seconds since the rider's position last arrived.
  ///
  /// In en, this message translates to:
  /// **'Live · {seconds}s ago'**
  String trackingLiveSeconds(int seconds);

  /// Tracking map: minutes since the rider's position last arrived (the rider may be offline).
  ///
  /// In en, this message translates to:
  /// **'Updated {minutes} min ago'**
  String trackingLiveMinutes(int minutes);

  /// Chip page: Beauty shelf heading.
  ///
  /// In en, this message translates to:
  /// **'Elevate Your Everyday Glow'**
  String get chipHeroBeautyShelfTitle;

  /// Chip page: line under the Beauty shelf heading.
  ///
  /// In en, this message translates to:
  /// **'Top beauty picks curated for you'**
  String get chipHeroBeautyShelfSubtitle;

  /// Chip page: big line over the gifting cards.
  ///
  /// In en, this message translates to:
  /// **'Perfect Gifts for Everyone'**
  String get chipGiftingTitle;

  /// Tracking screen: a step that has not started.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get trackingPending;

  /// Tracking screen: expected delivery when there is no estimate yet.
  ///
  /// In en, this message translates to:
  /// **'shown once your address is set'**
  String get trackingEtaUnset;

  /// Listing: heading of the sort sheet.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get listingSortBy;

  /// Listing: the sort chip when nothing else is chosen.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get listingSort;

  /// Listing: default sort order.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get listingRelevance;

  /// Listing: cheapest first.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get listingPriceLow;

  /// Listing: dearest first.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get listingPriceHigh;

  /// Listing: best rated first.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get listingRating;

  /// Listing: biggest discount first.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get listingDiscount;

  /// Listing: chip that keeps only discounted products.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get listingOffers;

  /// Listing: chip that keeps only what is in stock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get listingInStock;

  /// Listing: header while no address is set.
  ///
  /// In en, this message translates to:
  /// **'Set your delivery address'**
  String get listingSetAddress;

  /// Listing: header with the address.
  ///
  /// In en, this message translates to:
  /// **'Delivering to: {address}'**
  String listingDeliveringTo(String address);

  /// Listing: the bar that opens the cart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get listingViewCart;

  /// Listing: empty shelf.
  ///
  /// In en, this message translates to:
  /// **'No products here yet'**
  String get listingNoProducts;

  /// Listing: empty shelf because of the chips.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get listingNoMatches;

  /// Listing: how to see products again.
  ///
  /// In en, this message translates to:
  /// **'Try turning off a filter.'**
  String get listingTryClearingFilters;

  /// Listing: empty shelf advice.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, or pick something else.'**
  String get listingCheckBackSoon;

  /// Voice sheet: label of the tap-outside area.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get voiceClose;

  /// Voice sheet: example bubble.
  ///
  /// In en, this message translates to:
  /// **'Say \"Fresh tomatoes…\"'**
  String get voiceTipTomatoes;

  /// Voice sheet: example bubble for the photo path.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo of a pack'**
  String get voiceTipPhoto;

  /// Voice sheet: example bubble.
  ///
  /// In en, this message translates to:
  /// **'Say \"Amul milk and eggs…\"'**
  String get voiceTipMilkEggs;

  /// Voice sheet: example bubble.
  ///
  /// In en, this message translates to:
  /// **'Say \"Biscuits and chips…\"'**
  String get voiceTipBiscuits;

  /// Voice sheet: the recogniser failed.
  ///
  /// In en, this message translates to:
  /// **'Voice search stopped. Please try again.'**
  String get voiceStopped;

  /// Voice sheet: the microphone was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone for this app in Settings to search by voice.'**
  String get voiceMicSettings;

  /// Voice sheet: two quiet stretches in a row.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Tap Speak and try again.'**
  String get voiceDidNotCatch;

  /// Voice sheet: the big heading before anything is heard.
  ///
  /// In en, this message translates to:
  /// **'Search by voice\nor photo'**
  String get voiceTitle;

  /// Voice sheet: heading of the list being built.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list'**
  String get voiceShoppingList;

  /// Voice sheet: empty the list.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get voiceClearAll;

  /// Voice sheet: an item that matched no product.
  ///
  /// In en, this message translates to:
  /// **'No matching product yet'**
  String get voiceNoMatch;

  /// Voice sheet: run the search with what was said.
  ///
  /// In en, this message translates to:
  /// **'Show products'**
  String get voiceShowProducts;

  /// Voice sheet: take a photo.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get voiceCamera;

  /// Voice sheet: pick a photo.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get voiceGallery;

  /// Voice sheet: open the photo choices.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get voiceUpload;

  /// Voice sheet: start listening.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get voiceSpeak;

  /// Voice sheet: shown while it is listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get voiceListening;

  /// Festival page: small line above the title when the festival has none.
  ///
  /// In en, this message translates to:
  /// **'CELEBRATE'**
  String get festivalKickerFallback;

  /// Festival page: title when no festival is on.
  ///
  /// In en, this message translates to:
  /// **'Festive Store'**
  String get festivalTitleFallback;

  /// Festival page: first darshan card.
  ///
  /// In en, this message translates to:
  /// **'Mitti ke Ganpati'**
  String get festivalCardMittiKeGanpati;

  /// Festival page: line under a darshan card.
  ///
  /// In en, this message translates to:
  /// **'Ganpati darshan'**
  String get festivalCardGanpatiDarshan;

  /// Festival page: second darshan card.
  ///
  /// In en, this message translates to:
  /// **'Sthapana'**
  String get festivalCardSthapana;

  /// Festival page: shelf heading between festivals.
  ///
  /// In en, this message translates to:
  /// **'Festive picks'**
  String get festivalPicks;

  /// Festival page: shelf heading for the festival on today.
  ///
  /// In en, this message translates to:
  /// **'{chip} picks'**
  String festivalChipPicks(String chip);

  /// Festival page: line under the shelf heading.
  ///
  /// In en, this message translates to:
  /// **'Everything for the celebration'**
  String get festivalEverything;

  /// Festival page: empty state before a festival.
  ///
  /// In en, this message translates to:
  /// **'Festive store is getting ready'**
  String get festivalGettingReady;

  /// Festival page: empty state during a festival.
  ///
  /// In en, this message translates to:
  /// **'{name} specials are on their way'**
  String festivalSpecialsOnWay(String name);

  /// Festival page: line under the empty state.
  ///
  /// In en, this message translates to:
  /// **'Sellers are adding festive products. Check back soon.'**
  String get festivalEmptyBody;

  /// Festival artwork: button under the pooja row.
  ///
  /// In en, this message translates to:
  /// **'See all pooja essentials'**
  String get festivalSeeAllPooja;

  /// Bhog section: tile heading.
  ///
  /// In en, this message translates to:
  /// **'Modak Essentials'**
  String get festivalTileModak;

  /// Bhog section: tile heading.
  ///
  /// In en, this message translates to:
  /// **'Bhog Essentials'**
  String get festivalTileBhog;

  /// Bhog section: tile heading.
  ///
  /// In en, this message translates to:
  /// **'Cooking Staples'**
  String get festivalTileStaples;

  /// Bhog section: tile heading.
  ///
  /// In en, this message translates to:
  /// **'Cookware Picks'**
  String get festivalTileCookware;

  /// Bhog section: small line above the title.
  ///
  /// In en, this message translates to:
  /// **'PREPARE TRADITIONAL'**
  String get festivalBhogKicker;

  /// Bhog section: title.
  ///
  /// In en, this message translates to:
  /// **'Bhog & Festive Feasts'**
  String get festivalBhogTitle;

  /// Bhog section: line under the title.
  ///
  /// In en, this message translates to:
  /// **'Everything for the bhog and the feast'**
  String get festivalBhogSubtitle;

  /// Sign-in: skip to the shop.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get authSkip;

  /// Sign-in: heading of the page.
  ///
  /// In en, this message translates to:
  /// **'Log In or Sign Up'**
  String get authHeading;

  /// Sign-in: line under the heading.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or mobile number'**
  String get authHeadingSub;

  /// Sign-in: link to the reset page.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgot;

  /// Sign-in: small print before the policy links, ending in a line break.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to {app}\'\n'**
  String authAgree(String app);

  /// Sign-in: the terms link.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTerms;

  /// Sign-in: the word between the two policy links.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// Sign-in: the privacy link.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacy;

  /// Sign-in: hint when the field wants an email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailHint;

  /// Sign-in: hint when the field takes either.
  ///
  /// In en, this message translates to:
  /// **'Enter email or phone number'**
  String get authIdHint;

  /// Sign-in: password field hint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// Sign-in: no account for that email.
  ///
  /// In en, this message translates to:
  /// **'No login found with this email. New here?'**
  String get authNoLoginEmail;

  /// Sign-in: no account for that number.
  ///
  /// In en, this message translates to:
  /// **'No account on this number. New here?'**
  String get authNoLoginPhone;

  /// Sign-in: the register button.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// Sign-in: the main button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// Sign-in: the word on the line between the password form and the Google button.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

  /// Sign-in: the Google sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// Reset page: the email does not look like one.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEnterValidEmail;

  /// Reset page: title.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get authForgotTitle;

  /// Reset page: heading.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotQuestion;

  /// Reset page: line under the heading.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password'**
  String get authForgotBody;

  /// Reset page: the email field hint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Reset page: the button.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendReset;

  /// Reset page: back to the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get authBackToLogin;

  /// Reset page: the link was sent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authInbox;

  /// Reset page: which address the link went to.
  ///
  /// In en, this message translates to:
  /// **'We have sent a password reset link to\n{email}'**
  String authResetSent(String email);

  /// Opened from the password-reset email link: title and heading.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get authResetTitle;

  /// Opened from the password-reset email link: line under the heading.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account'**
  String get authResetBody;

  /// Opened from the password-reset email link: the new-password field hint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authResetNewPassword;

  /// Opened from the password-reset email link: the confirm-password field hint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authResetConfirmPassword;

  /// Opened from the password-reset email link: the button.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get authResetSubmit;

  /// Opened from the password-reset email link: shown once the new password is set.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get authResetDone;

  /// Opened from the password-reset email link: button after the password is updated.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authResetContinue;

  /// Password validation: too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// Password validation: confirmation field differs.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get authPasswordsDontMatch;

  /// Register page: title.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// Register page: line under the title.
  ///
  /// In en, this message translates to:
  /// **'Enter a few details to set up your account and start shopping.'**
  String get authCreateBody;

  /// Register page: name field hint.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get authUserName;

  /// Register page: phone field hint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhone;

  /// Register page: email field hint.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmailAddress;

  /// Register page: password field hint.
  ///
  /// In en, this message translates to:
  /// **'Password (6+ characters)'**
  String get authNewPassword;

  /// Register page: referral code field hint.
  ///
  /// In en, this message translates to:
  /// **'Friends Code (optional)'**
  String get authFriendsCode;

  /// Register page: the button.
  ///
  /// In en, this message translates to:
  /// **'Submit Securely'**
  String get authSubmit;

  /// Register page: line under the button.
  ///
  /// In en, this message translates to:
  /// **'You start as a customer. You can switch to Seller or Delivery Partner from your Profile later.'**
  String get authRoleNote;

  /// Seller home: page title.
  ///
  /// In en, this message translates to:
  /// **'Seller Dashboard'**
  String get sellerDashTitle;

  /// Seller home: nav label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get sellerDashNavHome;

  /// Seller home: nav label.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get sellerDashNavProducts;

  /// Seller home: nav label.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get sellerDashNavOrders;

  /// Seller home: nav label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get sellerDashNavMore;

  /// Seller home: while it loads.
  ///
  /// In en, this message translates to:
  /// **'Getting your store ready…'**
  String get sellerDashLoading;

  /// Seller home: the load failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your store'**
  String get sellerDashLoadFailed;

  /// Seller home: greeting with the seller name.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String sellerDashHi(String name);

  /// Seller home: line under the greeting.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how your store is doing.'**
  String get sellerDashSub;

  /// Seller home: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get sellerDashStatProducts;

  /// Seller home: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get sellerDashStatOrders;

  /// Seller home: rating card with no reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get sellerDashNoReviews;

  /// Seller home: how many reviews the rating is from.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 review} other{{count} reviews}}'**
  String sellerDashReviewCount(int count);

  /// Seller home: heading above the three buttons.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get sellerDashQuickActions;

  /// Seller home: quick action.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get sellerDashAddProduct;

  /// Seller home: quick action that opens the store page.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get sellerDashStore;

  /// Seller home: heading above the product strip.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get sellerDashMyProducts;

  /// Seller home: link to the full list.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get sellerDashViewAll;

  /// Seller home: empty product strip.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get sellerDashNoProducts;

  /// Seller home: line under the empty product strip.
  ///
  /// In en, this message translates to:
  /// **'Add your first product and it will show up in the shop straight away.'**
  String get sellerDashNoProductsBody;

  /// Seller home: heading above the recent orders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get sellerDashRecentOrders;

  /// Seller home: line under the empty orders block.
  ///
  /// In en, this message translates to:
  /// **'No orders yet. New ones land here the moment a customer checks out.'**
  String get sellerDashNoOrdersBody;

  /// Seller home: an order row, short id.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String sellerDashOrderNumber(String id);

  /// Seller products: hiding or unhiding failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this product.'**
  String get sellerProductsUpdateFailed;

  /// Seller products: delete confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete this product?'**
  String get sellerProductsDeleteTitle;

  /// Seller products: delete confirmation body, product name in quotes.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed. This cannot be undone.'**
  String sellerProductsDeleteBody(String name);

  /// Seller products: dialog button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sellerProductsCancel;

  /// Seller products: dialog button and menu item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sellerProductsDelete;

  /// Seller products: the delete failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete this product — it may already be part of past orders.'**
  String get sellerProductsDeleteFailed;

  /// Seller products: background removal failed, photo kept as picked.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the background — saving the original photo.'**
  String get sellerProductsBgFailed;

  /// Seller products: the new photo could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this photo.'**
  String get sellerProductsPhotoFailed;

  /// Seller products: the boost headline, pre-filled with the product name.
  ///
  /// In en, this message translates to:
  /// **'Check out {name}!'**
  String sellerProductsBoostDraft(String name);

  /// Seller products: boost request dialog title.
  ///
  /// In en, this message translates to:
  /// **'Boost This Product'**
  String get sellerProductsBoostTitle;

  /// Seller products: boost request, the headline field.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get sellerProductsBoostHeadline;

  /// Seller products: boost request, before the days dropdown.
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get sellerProductsBoostDuration;

  /// Seller products: one duration option, the fee already formatted.
  ///
  /// In en, this message translates to:
  /// **'{days,plural,=1{1 day} other{{days} days}} ({price})'**
  String sellerProductsBoostDays(int days, String price);

  /// Seller products: boost request, the confirm button.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get sellerProductsBoostRequest;

  /// Seller products: the boost request landed.
  ///
  /// In en, this message translates to:
  /// **'Boost request submitted for admin approval.'**
  String get sellerProductsBoostSent;

  /// Seller products: the boost request failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit boost request.'**
  String get sellerProductsBoostFailed;

  /// Seller products: page title.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get sellerProductsTitle;

  /// Seller products: while the list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading your products…'**
  String get sellerProductsLoading;

  /// Seller products: the list failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your products'**
  String get sellerProductsLoadFailed;

  /// Seller products: search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search your products'**
  String get sellerProductsSearchHint;

  /// Seller products: filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sellerProductsFilterAll;

  /// Seller products: filter chip.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sellerProductsFilterActive;

  /// Seller products: filter chip and the badge on a hidden product.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get sellerProductsFilterHidden;

  /// Seller products: filter chip.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get sellerProductsFilterLowStock;

  /// Seller products: empty list.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get sellerProductsEmptyTitle;

  /// Seller products: search or filter matched nothing.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get sellerProductsNoMatches;

  /// Seller products: line under the empty list.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first product — it shows up in the shop straight away.'**
  String get sellerProductsEmptyBody;

  /// Seller products: line under an empty search.
  ///
  /// In en, this message translates to:
  /// **'Try turning the search or a filter off.'**
  String get sellerProductsNoMatchesBody;

  /// Seller products: a product with no stock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get sellerProductsOutOfStock;

  /// Seller products: a product running low.
  ///
  /// In en, this message translates to:
  /// **'Low: {count} left'**
  String sellerProductsLowStock(int count);

  /// Seller products: how much stock is left.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String sellerProductsInStock(int count);

  /// Seller products: the edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sellerProductsEdit;

  /// Seller products: the menu item that requests a sponsored slot.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get sellerProductsBoost;

  /// Seller products: menu item, takes the product out of the shop.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get sellerProductsHide;

  /// Seller products: menu item, puts the product back in the shop.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get sellerProductsUnhide;

  /// Delivery: the button that claims a run waiting for pickup.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get deliveryAccept;

  /// Delivery: the button that marks a run as delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryDelivered;

  /// Delivery: link from the home preview to the full pickup list.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get deliveryViewAll;

  /// Delivery: a run whose delivery address is missing.
  ///
  /// In en, this message translates to:
  /// **'No address'**
  String get deliveryNoAddress;

  /// Delivery home: bottom bar label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get deliveryDashNavHome;

  /// Delivery home: bottom bar label.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveryDashNavDeliveries;

  /// Delivery home: bottom bar label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get deliveryDashNavMore;

  /// Delivery home: loading message.
  ///
  /// In en, this message translates to:
  /// **'Getting your runs ready…'**
  String get deliveryDashLoading;

  /// Delivery home: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your runs'**
  String get deliveryDashLoadFailed;

  /// Delivery home: the server refused the online switch.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your online status. Check your connection and try again.'**
  String get deliveryDashOnlineToggleFailed;

  /// Delivery home: rating card with no reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews'**
  String get deliveryDashNoReviews;

  /// Delivery home: how many reviews the rating is from.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 review} other{{count} reviews}}'**
  String deliveryDashReviewCount(int count);

  /// Delivery home: the delivery fee the rider gets for taking this order.
  ///
  /// In en, this message translates to:
  /// **'You earn {amount}'**
  String deliveryDashYouEarn(String amount);

  /// Delivery home: shown over the available orders while the rider is offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Go online to take new orders.'**
  String get deliveryDashOfflineNote;

  /// Delivery home: heading over the partner's claimed runs.
  ///
  /// In en, this message translates to:
  /// **'My Deliveries'**
  String get deliveryDashMyDeliveries;

  /// Delivery home: no claimed runs yet.
  ///
  /// In en, this message translates to:
  /// **'No active deliveries. Pick one up from the list below.'**
  String get deliveryDashNoActiveBody;

  /// Delivery home: heading over the runs waiting for pickup.
  ///
  /// In en, this message translates to:
  /// **'Available Orders'**
  String get deliveryDashAvailableOrders;

  /// Delivery home: the pickup list is empty.
  ///
  /// In en, this message translates to:
  /// **'No orders waiting for pickup right now. Pull down to check again.'**
  String get deliveryDashNoneWaitingBody;

  /// Delivery home: claiming a run from the preview failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t take this delivery — someone may have taken it first.'**
  String get deliveryDashClaimFailed;

  /// Delivery home: marking a run delivered failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark it delivered. Check your connection and try again.'**
  String get deliveryDashMarkDeliveredFailed;

  /// Delivery runs: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'My Delivery'**
  String get deliveryOrdersTitle;

  /// Delivery runs: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the runs…'**
  String get deliveryOrdersLoading;

  /// Delivery runs: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the runs'**
  String get deliveryOrdersLoadFailed;

  /// Delivery runs: another partner claimed the run first.
  ///
  /// In en, this message translates to:
  /// **'This order was just taken by another partner.'**
  String get deliveryOrdersClaimLost;

  /// Delivery runs: accepting a run failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t accept this order. Check your connection and try again.'**
  String get deliveryOrdersAcceptFailed;

  /// Delivery runs: marking a run delivered failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark this order delivered. Check your connection and try again.'**
  String get deliveryOrdersMarkDeliveredFailed;

  /// Delivery runs: the run is done but its earnings row is missing.
  ///
  /// In en, this message translates to:
  /// **'Marked delivered, but the delivery fee could not be recorded — tell the admin.'**
  String get deliveryOrdersFeeNotRecorded;

  /// Delivery runs: label over the store a run is collected from.
  ///
  /// In en, this message translates to:
  /// **'PICK FROM'**
  String get deliveryOrdersPickFrom;

  /// Delivery runs: label over the customer's address the run goes to.
  ///
  /// In en, this message translates to:
  /// **'DELIVER TO'**
  String get deliveryOrdersDeliverTo;

  /// Delivery runs: pickup name when the store's details could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'The seller\'s store'**
  String get deliveryOrdersStoreFallback;

  /// Delivery runs: the customer's own delivery instructions, when they left one.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String deliveryOrdersNote(String note);

  /// Delivery runs: button that calls the customer.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get deliveryOrdersCall;

  /// Delivery runs: the phone would not open a call.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the dialler.'**
  String get deliveryOrdersCallFailed;

  /// Delivery runs: button that opens the in-app map for directions.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get deliveryOrdersNavigate;

  /// Delivery runs: the in-app map's title when there is no store name to show instead.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get deliveryOrdersNavigateToStore;

  /// Delivery runs: the in-app map's title when heading to the delivery address.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get deliveryOrdersNavigateToCustomer;

  /// Delivery runs: the store or address has no lat/lng to show on the in-app map.
  ///
  /// In en, this message translates to:
  /// **'This location has no map coordinates yet.'**
  String get deliveryOrdersNavigateFailed;

  /// In-app navigation: screen title.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get deliveryNavigateTitle;

  /// In-app navigation: while the device's own position is being read.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get deliveryNavigateLocating;

  /// In-app navigation: straight-line distance to the destination.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String deliveryNavigateDistance(String distance);

  /// Directions: length and riding time of the road route to the destination.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {minutes} min by road'**
  String deliveryNavigateByRoad(String distance, int minutes);

  /// Directions: the road route could not be loaded; the map shows a straight line instead.
  ///
  /// In en, this message translates to:
  /// **'Road route unavailable — showing a straight line'**
  String get deliveryNavigateNoRoute;

  /// Directions: button that opens turn-by-turn navigation in Google Maps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get deliveryNavigateOpenMaps;

  /// Directions: no app could open the navigation link.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Google Maps.'**
  String get deliveryNavigateMapsFailed;

  /// In-app navigation: retries reading the device's location.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get deliveryNavigateRetry;

  /// In-app navigation: the floating button that re-fits the map.
  ///
  /// In en, this message translates to:
  /// **'Re-centre'**
  String get deliveryNavigateRecenter;

  /// Delivery earnings: the app bar title, and the More tile that opens it.
  ///
  /// In en, this message translates to:
  /// **'My Earnings'**
  String get deliveryEarningsTitle;

  /// Delivery earnings: loading message.
  ///
  /// In en, this message translates to:
  /// **'Adding up your earnings…'**
  String get deliveryEarningsLoading;

  /// Delivery earnings: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your earnings'**
  String get deliveryEarningsLoadFailed;

  /// Delivery earnings: label above the big total.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get deliveryEarningsTotal;

  /// Delivery earnings: the button that opens the payout requests.
  ///
  /// In en, this message translates to:
  /// **'Payouts & withdrawals'**
  String get deliveryEarningsPayouts;

  /// Delivery earnings: no fee has been earned yet.
  ///
  /// In en, this message translates to:
  /// **'No deliveries completed yet'**
  String get deliveryEarningsEmpty;

  /// Delivery earnings: an earnings row with no note of its own.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryEarningsFeeFallback;

  /// Delivery more: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get deliveryMoreTitle;

  /// Delivery more: the sign-out tile.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get deliveryMoreLogout;

  /// Admin users: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get adminUsersTitle;

  /// Admin users: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading users…'**
  String get adminUsersLoading;

  /// Admin users: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load users'**
  String get adminUsersLoadFailed;

  /// Admin users: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get adminUsersEmptyTitle;

  /// Admin users: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Everyone who signs up lands here, ready to be managed.'**
  String get adminUsersEmptyBody;

  /// Admin users: delete confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get adminUsersDeleteTitle;

  /// Admin users: delete confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes {name} and everything tied to their account (orders, products, addresses). This cannot be undone.'**
  String adminUsersDeleteBody(String name);

  /// Admin users: the delete dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminUsersCancel;

  /// Admin users: the delete dialog's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminUsersDelete;

  /// Admin users: an account was deleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get adminUsersDeleted;

  /// Admin users: the backend refused — it is the admin's own account.
  ///
  /// In en, this message translates to:
  /// **'You can\'t delete your own account.'**
  String get adminUsersErrSelf;

  /// Admin users: the backend refused — others were referred by it.
  ///
  /// In en, this message translates to:
  /// **'This account referred others and cannot be deleted yet.'**
  String get adminUsersErrReferred;

  /// Admin users: the backend refused — the caller is not an admin.
  ///
  /// In en, this message translates to:
  /// **'Only admins can delete accounts.'**
  String get adminUsersErrNotAdmin;

  /// Admin users: deleting failed for any other reason.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this account.'**
  String get adminUsersErrGeneric;

  /// Admin moderation: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get adminModerationTitle;

  /// Admin moderation: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the queue…'**
  String get adminModerationLoading;

  /// Admin moderation: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the queue'**
  String get adminModerationLoadFailed;

  /// Admin moderation: tile that opens the returns queue.
  ///
  /// In en, this message translates to:
  /// **'Return Requests'**
  String get adminModerationReturns;

  /// Admin moderation: subtitle under the returns tile.
  ///
  /// In en, this message translates to:
  /// **'Approve or reject customer returns'**
  String get adminModerationReturnsSub;

  /// Admin moderation: tile that opens the issues queue.
  ///
  /// In en, this message translates to:
  /// **'Order Issues'**
  String get adminModerationIssues;

  /// Admin moderation: subtitle under the issues tile.
  ///
  /// In en, this message translates to:
  /// **'Resolve reported problems'**
  String get adminModerationIssuesSub;

  /// Admin moderation: tile that opens the boost requests queue.
  ///
  /// In en, this message translates to:
  /// **'Sponsored Slots'**
  String get adminModerationSlots;

  /// Admin moderation: subtitle under the boost requests tile.
  ///
  /// In en, this message translates to:
  /// **'Approve seller boost requests'**
  String get adminModerationSlotsSub;

  /// Admin moderation: tile that opens the payout queue.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get adminModerationPayouts;

  /// Admin moderation: subtitle under the payouts tile.
  ///
  /// In en, this message translates to:
  /// **'What sellers and delivery partners are owed'**
  String get adminModerationPayoutsSub;

  /// Admin issues: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Order Issues'**
  String get adminIssuesTitle;

  /// Admin issues: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the issues…'**
  String get adminIssuesLoading;

  /// Admin issues: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the issues'**
  String get adminIssuesLoadFailed;

  /// Admin issues: empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing reported'**
  String get adminIssuesEmptyTitle;

  /// Admin issues: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Customer issues land here as soon as they are raised.'**
  String get adminIssuesEmptyBody;

  /// Admin issues: which order a ticket is about, by its short id.
  ///
  /// In en, this message translates to:
  /// **'Order: {id}'**
  String adminIssuesOrder(String id);

  /// Admin issues: the resolve dialog title.
  ///
  /// In en, this message translates to:
  /// **'Resolve Issue'**
  String get adminIssuesResolveTitle;

  /// Admin issues: the resolve dialog's refund field label.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount (₹, 0 if none)'**
  String get adminIssuesRefundLabel;

  /// Admin issues: the resolve dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminIssuesCancel;

  /// Admin issues: the dialog and card button that resolves a ticket.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get adminIssuesResolve;

  /// Admin issues: the card button that rejects a ticket.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminIssuesReject;

  /// Admin issues: resolve or reject failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this issue.'**
  String get adminIssuesUpdateFailed;

  /// Admin returns: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Return Requests'**
  String get adminReturnsTitle;

  /// Admin returns: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the requests…'**
  String get adminReturnsLoading;

  /// Admin returns: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the requests'**
  String get adminReturnsLoadFailed;

  /// Admin returns: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No return requests'**
  String get adminReturnsEmptyTitle;

  /// Admin returns: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Returns waiting on you will show up here.'**
  String get adminReturnsEmptyBody;

  /// Admin returns: which order a request is about, by its short id.
  ///
  /// In en, this message translates to:
  /// **'Order: {id}'**
  String adminReturnsOrder(String id);

  /// Admin returns: the approve dialog title.
  ///
  /// In en, this message translates to:
  /// **'Approve Return'**
  String get adminReturnsApproveTitle;

  /// Admin returns: the approve dialog's refund field label.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount (₹)'**
  String get adminReturnsRefundLabel;

  /// Admin returns: the approve dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminReturnsCancel;

  /// Admin returns: the dialog and card button that approves a request.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminReturnsApprove;

  /// Admin returns: the card button that rejects a request.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReturnsReject;

  /// Admin returns: approve or reject failed, likely the order's window.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this request — the order may be outside its return window.'**
  String get adminReturnsUpdateFailed;

  /// Admin slots: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Sponsored Slots'**
  String get adminSlotsTitle;

  /// Admin slots: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the slots…'**
  String get adminSlotsLoading;

  /// Admin slots: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the slots'**
  String get adminSlotsLoadFailed;

  /// Admin slots: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No sponsored slots'**
  String get adminSlotsEmptyTitle;

  /// Admin slots: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Slots you create show up here, with who has taken them.'**
  String get adminSlotsEmptyBody;

  /// Admin slots: a boost request whose product is gone.
  ///
  /// In en, this message translates to:
  /// **'Unknown product'**
  String get adminSlotsUnknownProduct;

  /// Admin slots: which product a boost request is for.
  ///
  /// In en, this message translates to:
  /// **'Product: {name}'**
  String adminSlotsProduct(String name);

  /// Admin slots: a request's duration and fee.
  ///
  /// In en, this message translates to:
  /// **'{days} days · {fee}'**
  String adminSlotsDaysFee(int days, String fee);

  /// Admin slots: the card button that approves a request.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminSlotsApprove;

  /// Admin slots: the dialog and card button that rejects a request.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminSlotsReject;

  /// Admin slots: the reject dialog title.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get adminSlotsRejectTitle;

  /// Admin slots: the reject dialog's reason field label.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get adminSlotsReasonLabel;

  /// Admin slots: the reject dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminSlotsCancel;

  /// Admin slots: approve or reject failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this request.'**
  String get adminSlotsUpdateFailed;

  /// Admin home: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashTitle;

  /// Admin home: bottom bar label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get adminDashNavHome;

  /// Admin home: bottom bar label.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminDashNavUsers;

  /// Admin home: bottom bar label.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get adminDashNavModeration;

  /// Admin home: loading message.
  ///
  /// In en, this message translates to:
  /// **'Counting the shop…'**
  String get adminDashLoading;

  /// Admin home: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the numbers'**
  String get adminDashLoadFailed;

  /// Admin home: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get adminDashStatProducts;

  /// Admin home: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get adminDashStatOrders;

  /// Admin home: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get adminDashStatSellers;

  /// Admin home: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Delivery Partners'**
  String get adminDashStatDelivery;

  /// Admin home: the card that opens the customer app as the editor.
  ///
  /// In en, this message translates to:
  /// **'View & edit your store'**
  String get adminDashEditorTitle;

  /// Admin home: how the store editor works.
  ///
  /// In en, this message translates to:
  /// **'Opens the app just as customers see it. Switch on Edit mode and tap the pencil on a banner, chip or festival to change it right there.'**
  String get adminDashEditorBody;

  /// Admin home: the tile that opens the categories editor.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get adminDashCategories;

  /// Admin home: subtitle under the categories tile.
  ///
  /// In en, this message translates to:
  /// **'Add, rename or hide the chips customers browse'**
  String get adminDashCategoriesSub;

  /// Admin home: heading over the latest orders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get adminDashRecentOrders;

  /// Admin home: there are no orders to preview.
  ///
  /// In en, this message translates to:
  /// **'No orders yet — the shop is quiet.'**
  String get adminDashNoOrders;

  /// Admin home: one recent order, by its short id.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String adminDashOrderNumber(String id);

  /// Admin payouts: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Payout Requests'**
  String get adminPayoutsTitle;

  /// Admin payouts: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the payout queue…'**
  String get adminPayoutsLoading;

  /// Admin payouts: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the payout queue'**
  String get adminPayoutsLoadFailed;

  /// Admin payouts: nobody is waiting for money.
  ///
  /// In en, this message translates to:
  /// **'No payouts waiting on a decision.'**
  String get adminPayoutsEmpty;

  /// Admin payouts: heading over the undecided requests.
  ///
  /// In en, this message translates to:
  /// **'Waiting on you ({count})'**
  String adminPayoutsWaiting(int count);

  /// Admin payouts: heading over the requests already handled.
  ///
  /// In en, this message translates to:
  /// **'Decided'**
  String get adminPayoutsDecided;

  /// Admin payouts: where the partner asked to be paid.
  ///
  /// In en, this message translates to:
  /// **'Send to {method}'**
  String adminPayoutsSendTo(String method);

  /// Admin payouts: the note a partner attached to their request.
  ///
  /// In en, this message translates to:
  /// **'Partner says: {note}'**
  String adminPayoutsPartnerNote(String note);

  /// Admin payouts: the card button that approves a request.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminPayoutsApprove;

  /// Admin payouts: the dialog and card button that rejects a request.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminPayoutsReject;

  /// Admin payouts: the reject dialog title.
  ///
  /// In en, this message translates to:
  /// **'Reject this payout?'**
  String get adminPayoutsRejectTitle;

  /// Admin payouts: the reject dialog's reason field label.
  ///
  /// In en, this message translates to:
  /// **'Reason (the partner will read this)'**
  String get adminPayoutsReasonLabel;

  /// Admin payouts: the reject dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminPayoutsCancel;

  /// Admin payouts: approve or reject failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this request. Try again.'**
  String get adminPayoutsUpdateFailed;

  /// Admin payouts: the paid dialog title, and the decided card's button.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get adminPayoutsMarkPaid;

  /// Admin payouts: the paid dialog's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get adminPayoutsMarkPaidButton;

  /// Admin payouts: the paid dialog's reference field label.
  ///
  /// In en, this message translates to:
  /// **'Bank / UPI reference (optional)'**
  String get adminPayoutsReferenceLabel;

  /// Admin payouts: helper text under the reference field.
  ///
  /// In en, this message translates to:
  /// **'So the transfer can be traced later'**
  String get adminPayoutsReferenceHelper;

  /// Admin payouts: marking a request paid failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark it paid. Try again.'**
  String get adminPayoutsMarkPaidFailed;

  /// Admin payouts: the bank reference a paid request was traced with.
  ///
  /// In en, this message translates to:
  /// **'Reference {ref}'**
  String adminPayoutsReference(String ref);

  /// Admin banners: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Banners'**
  String get adminBannersTitle;

  /// Admin banners: the button that adds one.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get adminBannersFab;

  /// Admin banners: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading banners…'**
  String get adminBannersLoading;

  /// Admin banners: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load banners'**
  String get adminBannersLoadFailed;

  /// Admin banners: how the list maps to Home's carousel.
  ///
  /// In en, this message translates to:
  /// **'These slide across the top of Home, in this order. Switch a banner off to hide it without deleting it.'**
  String get adminBannersHint;

  /// Admin banners: the list is empty.
  ///
  /// In en, this message translates to:
  /// **'No banners yet.'**
  String get adminBannersEmpty;

  /// Admin banners: the upload sheet's heading.
  ///
  /// In en, this message translates to:
  /// **'New banner'**
  String get adminBannersNew;

  /// Admin banners: the picture shape the carousel draws.
  ///
  /// In en, this message translates to:
  /// **'Shown at 851 × 396. Other shapes are cropped to fit.'**
  String get adminBannersShapeHint;

  /// Admin banners: the link field label in the upload sheet.
  ///
  /// In en, this message translates to:
  /// **'When tapped, open'**
  String get adminBannersLinkLabel;

  /// Admin banners: the link choice that opens no category.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get adminBannersLinkNothing;

  /// Admin banners: the upload sheet's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Upload banner'**
  String get adminBannersUpload;

  /// Admin banners: a banner was uploaded.
  ///
  /// In en, this message translates to:
  /// **'Banner added.'**
  String get adminBannersAdded;

  /// Admin banners: the upload failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the banner. Try again.'**
  String get adminBannersUploadFailed;

  /// Admin banners: switching a banner on or off failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update it.'**
  String get adminBannersUpdateFailed;

  /// Admin banners: moving a banner failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reorder.'**
  String get adminBannersReorderFailed;

  /// Admin banners: delete confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete this banner?'**
  String get adminBannersDeleteTitle;

  /// Admin banners: delete confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get adminBannersDeleteBody;

  /// Admin banners: the delete dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminBannersCancel;

  /// Admin banners: the delete dialog's confirm button and tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminBannersDelete;

  /// Admin banners: deleting failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete it.'**
  String get adminBannersDeleteFailed;

  /// Admin banners: a banner with no link.
  ///
  /// In en, this message translates to:
  /// **'Opens nothing'**
  String get adminBannersOpensNothing;

  /// Admin banners: what a banner opens when tapped.
  ///
  /// In en, this message translates to:
  /// **'Opens {target}'**
  String adminBannersOpens(String target);

  /// Admin banners: the tooltip on the up button.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get adminBannersMoveUp;

  /// Admin banners: the tooltip on the down button.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get adminBannersMoveDown;

  /// Admin categories: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get adminCategoriesTitle;

  /// Admin categories: the button that adds one.
  ///
  /// In en, this message translates to:
  /// **'Main category'**
  String get adminCategoriesFab;

  /// Admin categories: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading categories…'**
  String get adminCategoriesLoading;

  /// Admin categories: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load categories'**
  String get adminCategoriesLoadFailed;

  /// Admin categories: how the tree maps to what customers see.
  ///
  /// In en, this message translates to:
  /// **'Sub-categories become the cards, tiles and shelves on a store page. Home\'s chips (Electronics, Beauty, …) are fixed in the app, so a new main category shows up on the Categories tab, not as a Home chip.'**
  String get adminCategoriesHint;

  /// Admin categories: the editor heading for a new sub-category.
  ///
  /// In en, this message translates to:
  /// **'New sub-category'**
  String get adminCategoriesNewSub;

  /// Admin categories: the editor heading for a new main category.
  ///
  /// In en, this message translates to:
  /// **'New main category'**
  String get adminCategoriesNewMain;

  /// Admin categories: the editor heading when editing a sub-category.
  ///
  /// In en, this message translates to:
  /// **'Edit sub-category'**
  String get adminCategoriesEditSub;

  /// Admin categories: the editor heading when editing a main category.
  ///
  /// In en, this message translates to:
  /// **'Edit main category'**
  String get adminCategoriesEditMain;

  /// Admin categories: the editor's name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminCategoriesNameLabel;

  /// Admin categories: the editor's sort order field label.
  ///
  /// In en, this message translates to:
  /// **'Order (smaller comes first)'**
  String get adminCategoriesOrderLabel;

  /// Admin categories: the editor's visibility switch.
  ///
  /// In en, this message translates to:
  /// **'Show in the app'**
  String get adminCategoriesShowInApp;

  /// Admin categories: the editor's empty-name error.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get adminCategoriesErrName;

  /// Admin categories: the editor's duplicate-name error.
  ///
  /// In en, this message translates to:
  /// **'This name is already used'**
  String get adminCategoriesErrClash;

  /// Admin categories: the editor's save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminCategoriesSave;

  /// Admin categories: a category was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get adminCategoriesSaved;

  /// Admin categories: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check your connection and try again.'**
  String get adminCategoriesSaveFailed;

  /// Admin categories: why a main category with subs cannot be deleted.
  ///
  /// In en, this message translates to:
  /// **'Remove its sub-categories first.'**
  String get adminCategoriesRemoveSubsFirst;

  /// Admin categories: why a category with products cannot be deleted.
  ///
  /// In en, this message translates to:
  /// **'{count} products are in \"{name}\". Move them to another category first, or just switch it off.'**
  String adminCategoriesHasProducts(int count, String name);

  /// Admin categories: delete confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String adminCategoriesDeleteTitle(String name);

  /// Admin categories: delete confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get adminCategoriesDeleteBody;

  /// Admin categories: the delete dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCategoriesCancel;

  /// Admin categories: the delete dialog's confirm button and tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminCategoriesDelete;

  /// Admin categories: a category was deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get adminCategoriesDeleted;

  /// Admin categories: deleting failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete it.'**
  String get adminCategoriesDeleteFailed;

  /// Admin categories: switching a category on or off failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update it.'**
  String get adminCategoriesUpdateFailed;

  /// Admin categories: a main category's tile, counting its subs and products.
  ///
  /// In en, this message translates to:
  /// **'{subs,plural,=1{1 sub-category} other{{subs} sub-categories}} · {products,plural,=1{1 product} other{{products} products}}'**
  String adminCategoriesMainSubtitle(int subs, int products);

  /// Admin categories: the marker appended to a switched-off category.
  ///
  /// In en, this message translates to:
  /// **' · hidden'**
  String get adminCategoriesHidden;

  /// Admin categories: how many products a sub-category holds.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 product} other{{count} products}}'**
  String adminCategoriesProductsCount(int count);

  /// Admin categories: the button that adds a sub-category to a main one.
  ///
  /// In en, this message translates to:
  /// **'Sub-category'**
  String get adminCategoriesAddSub;

  /// Admin categories: the tooltip on the edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminCategoriesEdit;

  /// Admin festivals: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Festival calendar'**
  String get adminFestivalsTitle;

  /// Admin festivals: the button that adds one.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get adminFestivalsFab;

  /// Admin festivals: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading the calendar…'**
  String get adminFestivalsLoading;

  /// Admin festivals: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the calendar'**
  String get adminFestivalsLoadFailed;

  /// Admin festivals: the state of Home's chip when nothing is live.
  ///
  /// In en, this message translates to:
  /// **'No festival is on today, so Home shows the plain \"Festival\" chip.'**
  String get adminFestivalsNoneLive;

  /// Admin festivals: the festival that is on today, and its chip.
  ///
  /// In en, this message translates to:
  /// **'On today: {title}. Home\'s chip reads \"{chip}\".'**
  String adminFestivalsOnToday(String title, String chip);

  /// Admin festivals: the editor heading for a new festival.
  ///
  /// In en, this message translates to:
  /// **'New festival'**
  String get adminFestivalsNew;

  /// Admin festivals: the editor heading when editing a festival.
  ///
  /// In en, this message translates to:
  /// **'Edit festival'**
  String get adminFestivalsEditDialog;

  /// Admin festivals: the tooltip on the edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminFestivalsEdit;

  /// Admin festivals: the editor's chip field label.
  ///
  /// In en, this message translates to:
  /// **'Chip name (short, e.g. Diwali)'**
  String get adminFestivalsChipLabel;

  /// Admin festivals: the editor's kicker field label.
  ///
  /// In en, this message translates to:
  /// **'Small line (e.g. CELEBRATE)'**
  String get adminFestivalsKickerLabel;

  /// Admin festivals: the editor's title field label.
  ///
  /// In en, this message translates to:
  /// **'Big title (e.g. Ganesh Chaturthi)'**
  String get adminFestivalsTitleLabel;

  /// Admin festivals: the start date button.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String adminFestivalsFrom(String date);

  /// Admin festivals: the end date button.
  ///
  /// In en, this message translates to:
  /// **'To {date}'**
  String adminFestivalsTo(String date);

  /// Admin festivals: the editor's colours heading.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get adminFestivalsColours;

  /// Admin festivals: a colour preset's name.
  ///
  /// In en, this message translates to:
  /// **'Saffron'**
  String get adminFestivalsPresetSaffron;

  /// Admin festivals: a colour preset's name.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get adminFestivalsPresetRose;

  /// Admin festivals: a colour preset's name.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get adminFestivalsPresetGold;

  /// Admin festivals: a colour preset's name.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get adminFestivalsPresetGreen;

  /// Admin festivals: a colour preset's name.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get adminFestivalsPresetIndigo;

  /// Admin festivals: a colour preset's name.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get adminFestivalsPresetCoral;

  /// Admin festivals: the header colour field label.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get adminFestivalsHeader;

  /// Admin festivals: the fade colour field label.
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get adminFestivalsFade;

  /// Admin festivals: the accent colour field label.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get adminFestivalsAccent;

  /// Admin festivals: the editor's pooja artwork switch.
  ///
  /// In en, this message translates to:
  /// **'Show pooja artwork'**
  String get adminFestivalsShowPooja;

  /// Admin festivals: what the pooja artwork switch controls.
  ///
  /// In en, this message translates to:
  /// **'Pooja thali and the Bhog & Festive Feasts section'**
  String get adminFestivalsShowPoojaSub;

  /// Admin festivals: the editor's active switch.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminFestivalsActive;

  /// Admin festivals: the editor's missing-fields error.
  ///
  /// In en, this message translates to:
  /// **'Enter the chip name and title'**
  String get adminFestivalsErrChipTitle;

  /// Admin festivals: the editor's bad-colour error.
  ///
  /// In en, this message translates to:
  /// **'Colours must look like #FFD9A8'**
  String get adminFestivalsErrColours;

  /// Admin festivals: the editor's save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminFestivalsSave;

  /// Admin festivals: a festival was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get adminFestivalsSaved;

  /// Admin festivals: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check your connection and try again.'**
  String get adminFestivalsSaveFailed;

  /// Admin festivals: delete confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String adminFestivalsDeleteTitle(String name);

  /// Admin festivals: delete confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get adminFestivalsDeleteBody;

  /// Admin festivals: the delete dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminFestivalsCancel;

  /// Admin festivals: the delete dialog's confirm button and tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminFestivalsDelete;

  /// Admin festivals: deleting failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete it.'**
  String get adminFestivalsDeleteFailed;

  /// Admin festivals: the badge on the festival that is on today.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get adminFestivalsLive;

  /// Admin festivals: the marker for a festival that shows pooja artwork.
  ///
  /// In en, this message translates to:
  /// **' · pooja'**
  String get adminFestivalsPoojaSuffix;

  /// Admin festivals: the marker appended to a switched-off festival.
  ///
  /// In en, this message translates to:
  /// **' · off'**
  String get adminFestivalsOffSuffix;

  /// Seller reviews: the app bar title, and the More tile that opens it.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get sellerReviewsTitle;

  /// Seller reviews: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading your reviews…'**
  String get sellerReviewsLoading;

  /// Seller reviews: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your reviews'**
  String get sellerReviewsLoadFailed;

  /// Seller reviews: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get sellerReviewsEmptyTitle;

  /// Seller reviews: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Reviews buyers leave on your products show up here.'**
  String get sellerReviewsEmptyBody;

  /// Seller reviews: a review whose product is gone.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get sellerReviewsProductFallback;

  /// Seller boosts: the app bar title, and the More tile that opens it.
  ///
  /// In en, this message translates to:
  /// **'My Boost Requests'**
  String get sellerBoostsTitle;

  /// Seller boosts: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading your requests…'**
  String get sellerBoostsLoading;

  /// Seller boosts: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your requests'**
  String get sellerBoostsLoadFailed;

  /// Seller boosts: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No boost requests'**
  String get sellerBoostsEmptyTitle;

  /// Seller boosts: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Requests you send for a boost show up here with their status.'**
  String get sellerBoostsEmptyBody;

  /// Seller boosts: a request whose product is gone.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get sellerBoostsProductFallback;

  /// Seller boosts: which product a request is for.
  ///
  /// In en, this message translates to:
  /// **'Product: {name}'**
  String sellerBoostsProduct(String name);

  /// Seller boosts: a request's duration and fee.
  ///
  /// In en, this message translates to:
  /// **'{days} days · {fee}'**
  String sellerBoostsDaysFee(int days, String fee);

  /// Seller boosts: why a request was rejected.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String sellerBoostsReason(String reason);

  /// Seller earnings: the app bar title, and the More tile that opens it.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get sellerEarningsTitle;

  /// Seller earnings: loading message.
  ///
  /// In en, this message translates to:
  /// **'Adding up your earnings…'**
  String get sellerEarningsLoading;

  /// Seller earnings: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your earnings'**
  String get sellerEarningsLoadFailed;

  /// Seller earnings: label above the big total.
  ///
  /// In en, this message translates to:
  /// **'Net Payout'**
  String get sellerEarningsNetPayout;

  /// Seller earnings: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get sellerEarningsTotalSales;

  /// Seller earnings: stat card label.
  ///
  /// In en, this message translates to:
  /// **'Commission Paid'**
  String get sellerEarningsCommissionPaid;

  /// Seller earnings: the button that opens the payout requests.
  ///
  /// In en, this message translates to:
  /// **'Payouts & withdrawals'**
  String get sellerEarningsPayouts;

  /// Seller earnings: heading over the per-order list.
  ///
  /// In en, this message translates to:
  /// **'Delivered Orders ({count})'**
  String sellerEarningsDeliveredOrders(int count);

  /// Seller earnings: nothing has been delivered yet.
  ///
  /// In en, this message translates to:
  /// **'No delivered orders yet.'**
  String get sellerEarningsEmpty;

  /// Seller earnings: one delivered order, by its short id.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String sellerEarningsOrderNumber(String id);

  /// Seller more: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get sellerMoreTitle;

  /// Seller more: the section heading over the business tiles.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get sellerMoreSectionBusiness;

  /// Seller more: tile that opens the store profile editor.
  ///
  /// In en, this message translates to:
  /// **'Store Profile'**
  String get sellerMoreStore;

  /// Seller more: subtitle under the store profile tile.
  ///
  /// In en, this message translates to:
  /// **'Banner, logo, address, delivery radius'**
  String get sellerMoreStoreSub;

  /// Seller more: tile that opens the business details form.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get sellerMoreBusiness;

  /// Seller more: subtitle under the business details tile.
  ///
  /// In en, this message translates to:
  /// **'PAN, GST, bank account, UPI'**
  String get sellerMoreBusinessSub;

  /// Seller more: tile that opens the document uploads.
  ///
  /// In en, this message translates to:
  /// **'KYC Documents'**
  String get sellerMoreKyc;

  /// Seller more: subtitle under the KYC tile.
  ///
  /// In en, this message translates to:
  /// **'Upload verification documents'**
  String get sellerMoreKycSub;

  /// Seller more: the section heading over the performance tiles.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get sellerMoreSectionPerformance;

  /// Seller more: tile that opens the earnings breakdown.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get sellerMoreEarnings;

  /// Seller more: subtitle under the earnings tile.
  ///
  /// In en, this message translates to:
  /// **'Payouts and commission breakdown'**
  String get sellerMoreEarningsSub;

  /// Seller more: tile that opens the reviews list.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get sellerMoreReviews;

  /// Seller more: subtitle under the reviews tile.
  ///
  /// In en, this message translates to:
  /// **'What customers are saying'**
  String get sellerMoreReviewsSub;

  /// Seller more: tile that opens the boost request list.
  ///
  /// In en, this message translates to:
  /// **'My Boost Requests'**
  String get sellerMoreBoosts;

  /// Seller more: subtitle under the boost requests tile.
  ///
  /// In en, this message translates to:
  /// **'Sponsored product slot status'**
  String get sellerMoreBoostsSub;

  /// Seller more: the sign-out tile.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get sellerMoreLogout;

  /// Seller business details: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get sellerBusinessTitle;

  /// Seller business details: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading your details…'**
  String get sellerBusinessLoading;

  /// Seller business details: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your details'**
  String get sellerBusinessLoadFailed;

  /// Seller business details: saving without a business name.
  ///
  /// In en, this message translates to:
  /// **'Business name is required.'**
  String get sellerBusinessErrName;

  /// Seller business details: the form was saved.
  ///
  /// In en, this message translates to:
  /// **'Business details saved.'**
  String get sellerBusinessSaved;

  /// Seller business details: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your details.'**
  String get sellerBusinessSaveFailed;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get sellerBusinessNameLabel;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get sellerBusinessOwnerLabel;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get sellerBusinessAddressLabel;

  /// Seller business details: the heading over the PAN/GST/FSSAI fields.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get sellerBusinessCompliance;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get sellerBusinessPanLabel;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'GST Number (optional)'**
  String get sellerBusinessGstLabel;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'FSSAI Number (optional)'**
  String get sellerBusinessFssaiLabel;

  /// Seller business details: the heading over the bank/UPI fields.
  ///
  /// In en, this message translates to:
  /// **'Payout Details'**
  String get sellerBusinessPayoutDetails;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Number'**
  String get sellerBusinessBankLabel;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get sellerBusinessIfscLabel;

  /// Seller business details: field label.
  ///
  /// In en, this message translates to:
  /// **'UPI ID (optional)'**
  String get sellerBusinessUpiLabel;

  /// Seller business details: the save button.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get sellerBusinessSave;

  /// Seller business details wizard: moves to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get sellerBusinessNext;

  /// Seller business details wizard: returns to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sellerBusinessBack;

  /// Seller business details wizard: which step the seller is on.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String sellerBusinessStepOf(int step, int total);

  /// Seller product detail: a product whose name is missing.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get sellerProductDetailProductFallback;

  /// Seller product detail: the badge on a product taken out of the shop.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get sellerProductDetailHidden;

  /// Seller product detail: no stock left.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get sellerProductDetailOutOfStock;

  /// Seller product detail: how much stock is left.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String sellerProductDetailStock(int count);

  /// Seller product detail: heading over the description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sellerProductDetailDescription;

  /// Seller product detail: the description is empty.
  ///
  /// In en, this message translates to:
  /// **'No description added.'**
  String get sellerProductDetailNoDescription;

  /// Seller product detail: heading over the highlight chips.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get sellerProductDetailHighlights;

  /// Seller product detail: heading over the review list, with its count.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String sellerProductDetailReviews(int count);

  /// Seller product detail: the reviews could not be fetched.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the reviews.'**
  String get sellerProductDetailReviewsFailed;

  /// Seller product detail: retry the failed review load.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sellerProductDetailTryAgain;

  /// Seller product detail: nobody has reviewed this product.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet for this product.'**
  String get sellerProductDetailNoReviews;

  /// Seller product detail: the badge on a product customers can see and buy.
  ///
  /// In en, this message translates to:
  /// **'Live in shop'**
  String get sellerProductDetailLive;

  /// Seller product detail: stock is running low (5 or fewer).
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String sellerProductDetailLowStock(int count);

  /// Seller product detail: the discount against the MRP, next to the price.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String sellerProductDetailDiscountValue(int percent);

  /// Seller product detail: heading over units sold, revenue and rating.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get sellerProductDetailPerformance;

  /// Seller product detail: stat tile: units sold across orders that were not cancelled.
  ///
  /// In en, this message translates to:
  /// **'Units sold'**
  String get sellerProductDetailSold;

  /// Seller product detail: stat tile: money taken for this product.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get sellerProductDetailRevenue;

  /// Seller product detail: stat tile: the average review rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sellerProductDetailRating;

  /// Seller product detail: rating tile when there are no reviews.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get sellerProductDetailNoRating;

  /// Seller product detail: the sales numbers failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the sales.'**
  String get sellerProductDetailSalesFailed;

  /// Seller product detail: heading over category, pack size, brand and MRP.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sellerProductDetailDetails;

  /// Seller product detail: details row label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get sellerProductDetailCategory;

  /// Seller product detail: details row label for the unit, e.g. 1 kg.
  ///
  /// In en, this message translates to:
  /// **'Pack size'**
  String get sellerProductDetailUnit;

  /// Seller product detail: details row label.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get sellerProductDetailBrand;

  /// Seller product detail: details row label for the maximum retail price.
  ///
  /// In en, this message translates to:
  /// **'MRP'**
  String get sellerProductDetailMrp;

  /// Seller product detail: a details row with no value yet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get sellerProductDetailNotSet;

  /// Seller product detail: why to add a description, shown when there is none.
  ///
  /// In en, this message translates to:
  /// **'Customers buy more when they can read about a product. Write a few lines, or let AI draft them.'**
  String get sellerProductDetailAddDescriptionHint;

  /// Seller product detail: button that opens the edit screen to write a description.
  ///
  /// In en, this message translates to:
  /// **'Add description'**
  String get sellerProductDetailAddDescription;

  /// Seller product detail: bottom button that opens the edit screen.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get sellerProductDetailEdit;

  /// Seller product detail: bottom button that takes the product out of the shop.
  ///
  /// In en, this message translates to:
  /// **'Hide from shop'**
  String get sellerProductDetailHide;

  /// Seller product detail: bottom button that puts a hidden product back in the shop.
  ///
  /// In en, this message translates to:
  /// **'Show in shop'**
  String get sellerProductDetailUnhide;

  /// Seller product detail: confirmation after hiding.
  ///
  /// In en, this message translates to:
  /// **'Hidden from the shop.'**
  String get sellerProductDetailHiddenDone;

  /// Seller product detail: confirmation after showing again.
  ///
  /// In en, this message translates to:
  /// **'Back in the shop.'**
  String get sellerProductDetailShownDone;

  /// Seller product detail: hiding or showing failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this product.'**
  String get sellerProductDetailUpdateFailed;

  /// Seller orders: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get sellerOrdersTitle;

  /// Seller orders: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading your orders…'**
  String get sellerOrdersLoading;

  /// Seller orders: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your orders'**
  String get sellerOrdersLoadFailed;

  /// Seller orders: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get sellerOrdersEmptyTitle;

  /// Seller orders: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Orders from your customers land here the moment they check out.'**
  String get sellerOrdersEmptyBody;

  /// Seller orders: the filter chip that hides delivered and cancelled orders.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sellerOrdersChipActive;

  /// Seller orders: the filter chip that shows every order.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sellerOrdersChipAll;

  /// Seller orders: one order, by its short id.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String sellerOrdersOrderNumber(String id);

  /// Seller orders: an order line whose product name is missing.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get sellerOrdersItemFallback;

  /// Seller orders: the button after a new order arrives.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get sellerOrdersConfirm;

  /// Seller orders: the button on a confirmed order.
  ///
  /// In en, this message translates to:
  /// **'Start Preparing'**
  String get sellerOrdersPreparing;

  /// Seller orders: the button on an order being prepared.
  ///
  /// In en, this message translates to:
  /// **'Mark Ready for Pickup'**
  String get sellerOrdersReady;

  /// Seller orders: a status change failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this order.'**
  String get sellerOrdersUpdateFailed;

  /// Seller orders: cancel confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get sellerOrdersCancelTitle;

  /// Seller orders: what cancelling does to the customer.
  ///
  /// In en, this message translates to:
  /// **'The customer will be notified and any wallet amount used will be refunded automatically.'**
  String get sellerOrdersCancelBody;

  /// Seller orders: the cancel dialog's dismiss button.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get sellerOrdersNo;

  /// Seller orders: the card button that opens the cancel dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sellerOrdersCancel;

  /// Seller orders: the cancel dialog's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get sellerOrdersCancelConfirm;

  /// Store location picker: the phone's GPS is switched off.
  ///
  /// In en, this message translates to:
  /// **'Turn on location (GPS) on your phone.'**
  String get sellerLocationGpsOff;

  /// Store location picker: the permission is permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Allow it in app settings.'**
  String get sellerLocationPermissionBlocked;

  /// Store location picker: the snackbar button that opens the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sellerLocationSettings;

  /// Store location picker: the permission was denied this time.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to use GPS.'**
  String get sellerLocationPermissionNeeded;

  /// Store location picker: getting the GPS fix failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again outdoors.'**
  String get sellerLocationFailed;

  /// Store location picker: the typed address matched nothing.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that address. Add the city or pincode, or move the map.'**
  String get sellerLocationNotFound;

  /// Store location picker: the card before any pin is placed.
  ///
  /// In en, this message translates to:
  /// **'Use GPS, search an address, or move the map to place the pin.'**
  String get sellerLocationHint;

  /// Store location picker: the address under the pin is being looked up.
  ///
  /// In en, this message translates to:
  /// **'Finding address…'**
  String get sellerLocationResolving;

  /// Store location picker: the pin is set but its address could not be resolved.
  ///
  /// In en, this message translates to:
  /// **'Pin placed. Address lookup unavailable — you can type it in.'**
  String get sellerLocationLookupUnavailable;

  /// Seller store profile: the app bar title.
  ///
  /// In en, this message translates to:
  /// **'Store Profile'**
  String get sellerStoreTitle;

  /// Seller store profile: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading your store…'**
  String get sellerStoreLoading;

  /// Seller store profile: the load failed, with a retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your store'**
  String get sellerStoreLoadFailed;

  /// Seller store profile: the banner picker's label.
  ///
  /// In en, this message translates to:
  /// **'Store Banner'**
  String get sellerStoreBannerLabel;

  /// Seller store profile: the logo picker's label.
  ///
  /// In en, this message translates to:
  /// **'Store Logo'**
  String get sellerStoreLogoLabel;

  /// Seller store profile: the empty photo box's prompt.
  ///
  /// In en, this message translates to:
  /// **'Add {what}'**
  String sellerStoreAddPhoto(String what);

  /// Seller store profile: the store's approval chip.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get sellerStoreApproved;

  /// Seller store profile: the store's approval chip while it waits.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get sellerStorePendingApproval;

  /// Seller store profile: field label.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get sellerStoreNameLabel;

  /// Seller store profile: field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sellerStoreDescriptionLabel;

  /// Seller store profile: field label.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get sellerStoreAddressLabel;

  /// Seller store profile: field label.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get sellerStoreCityLabel;

  /// Seller store profile: field label.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get sellerStorePincodeLabel;

  /// Seller store profile: field label.
  ///
  /// In en, this message translates to:
  /// **'Delivery Radius (km)'**
  String get sellerStoreRadiusLabel;

  /// Seller store profile: the open/closed switch.
  ///
  /// In en, this message translates to:
  /// **'Store Open'**
  String get sellerStoreOpen;

  /// Seller store profile: the save button.
  ///
  /// In en, this message translates to:
  /// **'Save Store Profile'**
  String get sellerStoreSave;

  /// Seller store profile wizard: moves to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get sellerStoreNext;

  /// Seller store profile wizard: returns to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sellerStoreBack;

  /// Seller store profile wizard: which step the seller is on.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String sellerStoreStepOf(int step, int total);

  /// Seller store profile wizard: name of the last step, where the store is opened or closed and saved.
  ///
  /// In en, this message translates to:
  /// **'Open & save'**
  String get sellerStoreStepFinish;

  /// Seller store profile: the map card once the pin exists.
  ///
  /// In en, this message translates to:
  /// **'Store pin set  •  {lat}, {lng}'**
  String sellerStorePinSet(String lat, String lng);

  /// Seller store profile: the map card before any pin exists.
  ///
  /// In en, this message translates to:
  /// **'Store location not set'**
  String get sellerStorePinNotSet;

  /// Seller store profile: what the pin is for.
  ///
  /// In en, this message translates to:
  /// **'Customers and delivery partners use this pin to find you. Use live location, search your address, or drag the map.'**
  String get sellerStorePinHelp;

  /// Seller store profile: the button when a pin already exists.
  ///
  /// In en, this message translates to:
  /// **'Change location on map'**
  String get sellerStoreChangeLocation;

  /// Seller store profile: the button before any pin exists.
  ///
  /// In en, this message translates to:
  /// **'Set location on map'**
  String get sellerStoreSetLocation;

  /// Seller store profile: saving without a store name.
  ///
  /// In en, this message translates to:
  /// **'Store name is required.'**
  String get sellerStoreErrName;

  /// Seller store profile: the form was saved.
  ///
  /// In en, this message translates to:
  /// **'Store profile saved.'**
  String get sellerStoreSaved;

  /// Seller store profile: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your store profile.'**
  String get sellerStoreSaveFailed;

  /// Seller store profile: the pin's address differs from the typed one.
  ///
  /// In en, this message translates to:
  /// **'Update address?'**
  String get sellerStoreUpdateAddressTitle;

  /// Seller store profile: the offered address swap.
  ///
  /// In en, this message translates to:
  /// **'The pin is at:\n\n{address}\n\nReplace the address, city and pincode with this?'**
  String sellerStoreUpdateAddressBody(String address);

  /// Seller store profile: keep the typed address.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get sellerStoreKeepMine;

  /// Seller store profile: take the pin's address.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get sellerStoreUseThis;

  /// Seller store profile: the location picker screen's title.
  ///
  /// In en, this message translates to:
  /// **'Store Location'**
  String get sellerStorePickTitle;

  /// Seller store profile: the location picker's search hint.
  ///
  /// In en, this message translates to:
  /// **'Search store address, area or pincode'**
  String get sellerStorePickHint;

  /// Seller store profile: the location picker's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Confirm store location'**
  String get sellerStorePickConfirm;

  /// Add product: the app bar title for a new product.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// Add product: the app bar title when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get addProductEditTitle;

  /// Add product: the category chooser could not be filled.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the category list.'**
  String get addProductCategoriesFailed;

  /// Add product: retry the failed category load.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get addProductTryAgain;

  /// Add product: the category dropdown's label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addProductCategoryLabel;

  /// Add product: the category field before one is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get addProductCategoryChoose;

  /// Category picker: the sheet's title.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get categoryPickerTitle;

  /// Category picker: the search box hint.
  ///
  /// In en, this message translates to:
  /// **'Search, e.g. toys, candles, coffee'**
  String get categoryPickerSearchHint;

  /// Category picker: clears the search box.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get categoryPickerClear;

  /// Category picker: goes back from a group's sub-categories.
  ///
  /// In en, this message translates to:
  /// **'Back to all categories'**
  String get categoryPickerBack;

  /// Category picker: how many sub-categories a group has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 category} other{{count} categories}}'**
  String categoryPickerCount(int count);

  /// Category picker: the search found nothing.
  ///
  /// In en, this message translates to:
  /// **'No category matches \"{query}\".'**
  String categoryPickerNoMatch(String query);

  /// Add product: more photos were picked than there is room for.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} photos — extra ones skipped.'**
  String addProductPhotosSkipped(int max);

  /// Add product: some cut-outs failed; those photos keep their original.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the background from some photos — the originals will be used.'**
  String get addProductBgSomeFailed;

  /// Add product: the AI description needs a name to work from.
  ///
  /// In en, this message translates to:
  /// **'Enter a product name first'**
  String get addProductErrName;

  /// Add product: the AI description request failed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate description'**
  String get addProductGenerateFailed;

  /// Add product: saving without the required fields.
  ///
  /// In en, this message translates to:
  /// **'Enter a name, category, and price'**
  String get addProductErrRequired;

  /// Add product: saving while a cut-out is still running.
  ///
  /// In en, this message translates to:
  /// **'Please wait — removing the background…'**
  String get addProductWaitBg;

  /// Add product: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this product. Please try again.'**
  String get addProductSaveFailed;

  /// Add product: the empty photo box's prompt.
  ///
  /// In en, this message translates to:
  /// **'Tap to add product photos'**
  String get addProductTapToAdd;

  /// Add product: how many photos may be added.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String addProductUpTo(int max);

  /// Add product: the tile that adds more photos.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addProductAddMore;

  /// Add product: the photo strip's helper line.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} photos · the first one is the main photo — tap another to make it main'**
  String addProductPhotosHelp(int count, int max);

  /// Add product: the badge on the photo used on cards and listings.
  ///
  /// In en, this message translates to:
  /// **'MAIN'**
  String get addProductMainBadge;

  /// Add product: the cut-out switch.
  ///
  /// In en, this message translates to:
  /// **'Remove background'**
  String get addProductRemoveBg;

  /// Add product: the cut-out switch, on.
  ///
  /// In en, this message translates to:
  /// **'New photos are cut out automatically'**
  String get addProductRemoveBgOn;

  /// Add product: the cut-out switch, off.
  ///
  /// In en, this message translates to:
  /// **'Photo will be saved as it is'**
  String get addProductRemoveBgOff;

  /// Add product: field label.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get addProductNameLabel;

  /// Add product: the brand section's heading.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get addProductBrandLabel;

  /// Add product: the chip that sells under the seller's own name.
  ///
  /// In en, this message translates to:
  /// **'My store: {name}'**
  String addProductMyStore(String name);

  /// Add product: the chip that sells under a company's brand.
  ///
  /// In en, this message translates to:
  /// **'Company brand'**
  String get addProductCompanyBrand;

  /// Add product: what selling under your own name means.
  ///
  /// In en, this message translates to:
  /// **'Customers will see this under your business brand \"{name}\".'**
  String addProductMyStoreNote(String name);

  /// Add product: the brand field when no store name is known.
  ///
  /// In en, this message translates to:
  /// **'Company brand (optional)'**
  String get addProductCompanyBrandOptional;

  /// Add product: the brand field's hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apple, Samsung, Amul'**
  String get addProductBrandHint;

  /// Add product: the brand field's helper when no store name is known.
  ///
  /// In en, this message translates to:
  /// **'Set up your store profile to sell under your own business name.'**
  String get addProductBrandHelper;

  /// Add product: field label.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get addProductPriceLabel;

  /// Add product: field label.
  ///
  /// In en, this message translates to:
  /// **'MRP (optional)'**
  String get addProductMrpLabel;

  /// Add product: field label.
  ///
  /// In en, this message translates to:
  /// **'Unit (e.g. 1 kg)'**
  String get addProductUnitLabel;

  /// Add product: field label.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get addProductStockLabel;

  /// Add product: the heading over the description field.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get addProductDescriptionLabel;

  /// Add product: the button that writes the description.
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get addProductGenerate;

  /// Add product: the description field's hint.
  ///
  /// In en, this message translates to:
  /// **'What is this product? What makes it worth buying?'**
  String get addProductDescriptionHint;

  /// Add product: the heading over the highlight chips.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get addProductHighlights;

  /// Add product: the AI button's label while the writer is working.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get addProductGenerating;

  /// Add product: the AI button's label after an answer that stopped short of the 700-word floor — the next tap continues the page instead of starting it again.
  ///
  /// In en, this message translates to:
  /// **'Add more with AI'**
  String get addProductExtend;

  /// Add product: the line under the Description heading that says what the AI writer produces.
  ///
  /// In en, this message translates to:
  /// **'The AI writes {min}–{max} words: what it is, why it is worth buying, what is in the pack, how to use it, and what buyers ask.'**
  String addProductDescriptionRule(int min, int max);

  /// Add product: the live word count under the description box, against the length rule the AI writes to.
  ///
  /// In en, this message translates to:
  /// **'{count} words · target {min}–{max}'**
  String addProductWordCount(int count, int min, int max);

  /// Add product: what the word count line says while the AI writer is working.
  ///
  /// In en, this message translates to:
  /// **'Writing a full page — about a minute for 700 to 1500 words.'**
  String get addProductWritingHelp;

  /// Add product: the AI writer ran out of its time budget before reaching 700 words, and the text it did write is in the box.
  ///
  /// In en, this message translates to:
  /// **'Only {count} words so far — tap Generate again to extend the page.'**
  String addProductGenerateShort(int count);

  /// Add product: no AI provider is configured on the server, so the page was composed from what the seller typed. The reasons the provider itself failed are said apart, in their own lines.
  ///
  /// In en, this message translates to:
  /// **'Written from your own notes — the AI did not write this, because the server has no AI key set.'**
  String get addProductGenerateFromNotes;

  /// Add product: the AI writer could not reach Duggu because the device has no connection.
  ///
  /// In en, this message translates to:
  /// **'No internet — the AI writer needs a connection.'**
  String get addProductGenerateOffline;

  /// Add product: the AI writer did not answer inside the app's waiting time.
  ///
  /// In en, this message translates to:
  /// **'The AI writer took too long this time. Tap Generate again.'**
  String get addProductGenerateSlow;

  /// Add product: the seller's session has gone, and the writer answers a signed-in seller only.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to use the AI writer.'**
  String get addProductGenerateSignIn;

  /// Add product: the generate-product-description Edge Function is missing from the Supabase project.
  ///
  /// In en, this message translates to:
  /// **'The AI writer is not deployed on this project yet — see supabase/README.md.'**
  String get addProductGenerateMissing;

  /// Add product: either this account or the store's AI provider is being paced. Neither is phrased as the seller's fault, because the seller cannot tell them apart and cannot fix either.
  ///
  /// In en, this message translates to:
  /// **'Too many descriptions at once, right now. Wait a minute and try again.'**
  String get addProductGenerateRateLimited;

  /// Add product: the writer answered with a server error the app could not name. The reason is in the Supabase log, and it is deliberately not guessed at here - the old sentence blamed a busy service for what was usually a broken deployment.
  ///
  /// In en, this message translates to:
  /// **'The AI writer on the server failed. Try again in a minute.'**
  String get addProductGenerateBusy;

  /// Add product: the writer replied, but the reply was not a description the app could read.
  ///
  /// In en, this message translates to:
  /// **'The AI writer answered with something unreadable. Try again in a minute.'**
  String get addProductGenerateGarbled;

  /// Add product: the writer answered, but with no description in the answer.
  ///
  /// In en, this message translates to:
  /// **'The AI writer came back with nothing. Tap Generate again.'**
  String get addProductGenerateEmpty;

  /// Add product: the provider refused the store's AI key, or AI_BASE_URL is not an address. Retrying cannot change it, so no retry button is offered next to this line.
  ///
  /// In en, this message translates to:
  /// **'The AI writer\'s key or address on the server is wrong.'**
  String get addProductGenerateMisconfigured;

  /// Add product: the Edge Function threw. The seller can do nothing about it, which is the point of saying so instead of asking them to wait.
  ///
  /// In en, this message translates to:
  /// **'The AI writer broke on the server. Its log says why.'**
  String get addProductGenerateCrashed;

  /// Add product: no model wrote the page because the store's key was refused, so the seller has a page and the owner has something to fix.
  ///
  /// In en, this message translates to:
  /// **'Written from your own notes — the AI key was refused.'**
  String get addProductGenerateAiRefused;

  /// Add product: the AI service could not be reached at all, or the model named on the server does not exist there.
  ///
  /// In en, this message translates to:
  /// **'Written from your own notes — the AI address is wrong.'**
  String get addProductGenerateAiAddress;

  /// Add product: the provider timed out, throttled, or failed. This is the one case where another tap is the right advice.
  ///
  /// In en, this message translates to:
  /// **'Written from your own notes — the AI service was slow or down. Tap Generate again.'**
  String get addProductGenerateAiDown;

  /// Add product: the save button when editing.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get addProductUpdate;

  /// Add product: the save button for a new product.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get addProductSave;

  /// Seller screens: sellerBusinessErrRequired
  ///
  /// In en, this message translates to:
  /// **'This is needed.'**
  String get sellerBusinessErrRequired;

  /// Seller screens: sellerBusinessErrPan
  ///
  /// In en, this message translates to:
  /// **'A PAN is 10 characters: 5 letters, 4 digits, 1 letter (ABCDE1234F).'**
  String get sellerBusinessErrPan;

  /// Seller screens: sellerBusinessErrGst
  ///
  /// In en, this message translates to:
  /// **'A GSTIN is 15 characters, like 22ABCDE1234F1Z5.'**
  String get sellerBusinessErrGst;

  /// Seller screens: sellerBusinessErrFssai
  ///
  /// In en, this message translates to:
  /// **'An FSSAI licence number is 14 digits.'**
  String get sellerBusinessErrFssai;

  /// Seller screens: sellerBusinessErrBank
  ///
  /// In en, this message translates to:
  /// **'An account number is 9 to 18 digits, with no spaces or commas.'**
  String get sellerBusinessErrBank;

  /// Seller screens: sellerBusinessErrIfsc
  ///
  /// In en, this message translates to:
  /// **'An IFSC is 11 characters, like SBIN0001234 (the 5th is a zero).'**
  String get sellerBusinessErrIfsc;

  /// Seller screens: sellerBusinessErrUpi
  ///
  /// In en, this message translates to:
  /// **'A UPI ID looks like name@bank.'**
  String get sellerBusinessErrUpi;

  /// Seller screens: sellerBusinessErrIfscNeeded
  ///
  /// In en, this message translates to:
  /// **'Add the IFSC of this account, or payouts cannot reach it.'**
  String get sellerBusinessErrIfscNeeded;

  /// Seller screens: sellerBusinessErrBankNeeded
  ///
  /// In en, this message translates to:
  /// **'Add the account number this IFSC belongs to.'**
  String get sellerBusinessErrBankNeeded;

  /// Seller screens: sellerBusinessFixErrors
  ///
  /// In en, this message translates to:
  /// **'Some details need fixing — see the red notes below.'**
  String get sellerBusinessFixErrors;

  /// Seller screens: sellerBusinessApprovedTitle
  ///
  /// In en, this message translates to:
  /// **'Approved — you can sell'**
  String get sellerBusinessApprovedTitle;

  /// Seller screens: sellerBusinessApprovedBody
  ///
  /// In en, this message translates to:
  /// **'Your business is verified. Changing these details may send it back for review.'**
  String get sellerBusinessApprovedBody;

  /// Seller screens: sellerBusinessRejectedTitle
  ///
  /// In en, this message translates to:
  /// **'Not approved yet'**
  String get sellerBusinessRejectedTitle;

  /// Seller screens: sellerBusinessRejectedBody
  ///
  /// In en, this message translates to:
  /// **'Some details could not be verified. Correct them and save to be reviewed again.'**
  String get sellerBusinessRejectedBody;

  /// Seller screens: sellerBusinessPendingTitle
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get sellerBusinessPendingTitle;

  /// Seller screens: sellerBusinessPendingBody
  ///
  /// In en, this message translates to:
  /// **'We are checking your details. This usually takes 1–2 working days.'**
  String get sellerBusinessPendingBody;

  /// Seller screens: sellerBusinessSectionBusiness
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get sellerBusinessSectionBusiness;

  /// Seller screens: sellerBusinessSectionBusinessBody
  ///
  /// In en, this message translates to:
  /// **'The name and address on your invoices.'**
  String get sellerBusinessSectionBusinessBody;

  /// Seller screens: sellerBusinessComplianceBody
  ///
  /// In en, this message translates to:
  /// **'Needed to verify your business. GST and FSSAI only if you have them.'**
  String get sellerBusinessComplianceBody;

  /// Seller screens: sellerBusinessFssaiHint
  ///
  /// In en, this message translates to:
  /// **'14-digit number'**
  String get sellerBusinessFssaiHint;

  /// Seller screens: sellerBusinessFssaiHelper
  ///
  /// In en, this message translates to:
  /// **'Needed if you sell food.'**
  String get sellerBusinessFssaiHelper;

  /// Seller screens: sellerBusinessPayoutBody
  ///
  /// In en, this message translates to:
  /// **'Where your earnings are sent.'**
  String get sellerBusinessPayoutBody;

  /// Seller screens: sellerBusinessBankHint
  ///
  /// In en, this message translates to:
  /// **'Digits only'**
  String get sellerBusinessBankHint;

  /// Seller screens: sellerBusinessIfscHelper
  ///
  /// In en, this message translates to:
  /// **'Printed on your cheque book or passbook.'**
  String get sellerBusinessIfscHelper;

  /// Seller screens: kycHintPan
  ///
  /// In en, this message translates to:
  /// **'A clear photo of the front of your PAN card.'**
  String get kycHintPan;

  /// Seller screens: kycHintGst
  ///
  /// In en, this message translates to:
  /// **'Your GST registration certificate, if you have one.'**
  String get kycHintGst;

  /// Seller screens: kycHintFssai
  ///
  /// In en, this message translates to:
  /// **'Your FSSAI licence, if you sell food.'**
  String get kycHintFssai;

  /// Seller screens: kycHintBank
  ///
  /// In en, this message translates to:
  /// **'A cancelled cheque or the first page of your passbook.'**
  String get kycHintBank;

  /// Seller screens: kycHintAddress
  ///
  /// In en, this message translates to:
  /// **'Aadhaar, electricity bill or rent agreement.'**
  String get kycHintAddress;

  /// Seller screens: kycTakePhoto
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get kycTakePhoto;

  /// Seller screens: kycFromGallery
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get kycFromGallery;

  /// Seller screens: kycAllVerified
  ///
  /// In en, this message translates to:
  /// **'All documents verified'**
  String get kycAllVerified;

  /// Seller screens: kycProgress
  ///
  /// In en, this message translates to:
  /// **'{verified} of {total} required documents verified'**
  String kycProgress(int verified, int total);

  /// Seller screens: kycAllVerifiedBody
  ///
  /// In en, this message translates to:
  /// **'Nothing more to do here.'**
  String get kycAllVerifiedBody;

  /// Seller screens: kycUploadRemaining
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Upload 1 more required document to be reviewed.} other{Upload {count} more required documents to be reviewed.}}'**
  String kycUploadRemaining(int count);

  /// Seller screens: kycUnderReviewBody
  ///
  /// In en, this message translates to:
  /// **'Everything is uploaded. We will verify it within 1–2 working days.'**
  String get kycUnderReviewBody;

  /// Seller screens: kycStatusUnderReview
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get kycStatusUnderReview;

  /// Seller screens: kycRequired
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get kycRequired;

  /// Seller screens: kycOptional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get kycOptional;

  /// Seller screens: kycNotUploaded
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get kycNotUploaded;

  /// Seller screens: kycRejectedHelp
  ///
  /// In en, this message translates to:
  /// **'This could not be verified. Upload a clearer copy.'**
  String get kycRejectedHelp;

  /// Seller screens: sellerEarningsAllTime
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get sellerEarningsAllTime;

  /// Seller screens: sellerEarningsThisMonth
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get sellerEarningsThisMonth;

  /// Seller screens: sellerEarningsLast7Days
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get sellerEarningsLast7Days;

  /// Seller screens: sellerEarningsFromOrders
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No delivered orders} =1{From 1 delivered order} other{From {count} delivered orders}}'**
  String sellerEarningsFromOrders(int count);

  /// Seller screens: sellerEarningsEmptyPeriod
  ///
  /// In en, this message translates to:
  /// **'No delivered orders in this period.'**
  String get sellerEarningsEmptyPeriod;

  /// Seller screens: sellerEarningsHowItWorks
  ///
  /// In en, this message translates to:
  /// **'Money reaches this page when an order is delivered: the sale, less the platform\'s commission, is your payout.'**
  String get sellerEarningsHowItWorks;

  /// Seller screens: sellerEarningsBreakdown
  ///
  /// In en, this message translates to:
  /// **'Sale {sales} · Commission {commission}'**
  String sellerEarningsBreakdown(String sales, String commission);

  /// Seller screens: sellerOrdersJustNow
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get sellerOrdersJustNow;

  /// Seller screens: sellerOrdersMinutesAgo
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String sellerOrdersMinutesAgo(int count);

  /// Seller screens: sellerOrdersHoursAgo
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String sellerOrdersHoursAgo(int count);

  /// Seller screens: sellerOrdersWaitingPickup
  ///
  /// In en, this message translates to:
  /// **'Packed and ready. A delivery partner will pick it up.'**
  String get sellerOrdersWaitingPickup;

  /// Seller screens: sellerOrdersOnTheWay
  ///
  /// In en, this message translates to:
  /// **'On its way to the customer.'**
  String get sellerOrdersOnTheWay;

  /// Seller screens: sellerOrdersItemCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String sellerOrdersItemCount(int count);

  /// Seller screens: sellerOrdersMoreItems
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 more item} other{+{count} more items}}'**
  String sellerOrdersMoreItems(int count);

  /// Seller screens: sellerStoreErrPincode
  ///
  /// In en, this message translates to:
  /// **'A PIN code is 6 digits.'**
  String get sellerStoreErrPincode;

  /// Seller screens: sellerStorePendingBody
  ///
  /// In en, this message translates to:
  /// **'Customers will see your store once it is approved.'**
  String get sellerStorePendingBody;

  /// Seller screens: sellerStoreSectionBranding
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get sellerStoreSectionBranding;

  /// Seller screens: sellerStoreSectionBrandingBody
  ///
  /// In en, this message translates to:
  /// **'The first thing customers see. A wide banner and a square logo work best.'**
  String get sellerStoreSectionBrandingBody;

  /// Seller screens: sellerStoreSectionAbout
  ///
  /// In en, this message translates to:
  /// **'About your store'**
  String get sellerStoreSectionAbout;

  /// Seller screens: sellerStoreSectionAboutBody
  ///
  /// In en, this message translates to:
  /// **'Your name and a line on what you sell.'**
  String get sellerStoreSectionAboutBody;

  /// Seller screens: sellerStoreDescriptionHint
  ///
  /// In en, this message translates to:
  /// **'e.g. Fresh fruit, vegetables and daily groceries, delivered the same day.'**
  String get sellerStoreDescriptionHint;

  /// Seller screens: sellerStoreSectionAddress
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get sellerStoreSectionAddress;

  /// Seller screens: sellerStoreSectionAddressBody
  ///
  /// In en, this message translates to:
  /// **'Where your store is. Shown to customers and delivery partners.'**
  String get sellerStoreSectionAddressBody;

  /// Seller screens: sellerStoreSectionDelivery
  ///
  /// In en, this message translates to:
  /// **'Location & delivery'**
  String get sellerStoreSectionDelivery;

  /// Seller screens: sellerStoreSectionDeliveryBody
  ///
  /// In en, this message translates to:
  /// **'Your pin on the map and how far you deliver.'**
  String get sellerStoreSectionDeliveryBody;

  /// Seller screens: sellerStoreRadiusHelper
  ///
  /// In en, this message translates to:
  /// **'Customers farther than this will not see your products.'**
  String get sellerStoreRadiusHelper;

  /// Seller screens: sellerStoreOpenBody
  ///
  /// In en, this message translates to:
  /// **'Customers can order from you now.'**
  String get sellerStoreOpenBody;

  /// Seller screens: sellerStoreClosedBody
  ///
  /// In en, this message translates to:
  /// **'Your store shows as closed and takes no orders.'**
  String get sellerStoreClosedBody;

  /// Seller screens: sellerStoreMissingBanner
  ///
  /// In en, this message translates to:
  /// **'banner'**
  String get sellerStoreMissingBanner;

  /// Seller screens: sellerStoreMissingLogo
  ///
  /// In en, this message translates to:
  /// **'logo'**
  String get sellerStoreMissingLogo;

  /// Seller screens: sellerStoreMissingDescription
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get sellerStoreMissingDescription;

  /// Seller screens: sellerStoreMissingAddress
  ///
  /// In en, this message translates to:
  /// **'full address'**
  String get sellerStoreMissingAddress;

  /// Seller screens: sellerStoreMissingPin
  ///
  /// In en, this message translates to:
  /// **'map pin'**
  String get sellerStoreMissingPin;

  /// Seller screens: sellerStoreComplete
  ///
  /// In en, this message translates to:
  /// **'Store profile {percent}% complete'**
  String sellerStoreComplete(int percent);

  /// Seller screens: sellerStoreStillMissing
  ///
  /// In en, this message translates to:
  /// **'Still to add: {items}.'**
  String sellerStoreStillMissing(String items);

  /// Checkout screen: button to pick a different delivery address.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get checkoutChange;

  /// Checkout screen: title of the sheet listing saved addresses.
  ///
  /// In en, this message translates to:
  /// **'Choose a delivery address'**
  String get checkoutPickAddress;

  /// Address sheet: button that opens the form for a new delivery address.
  ///
  /// In en, this message translates to:
  /// **'Add a new address'**
  String get checkoutAddAddress;

  /// Receiver sheet: title, asked when the account has no name or phone yet.
  ///
  /// In en, this message translates to:
  /// **'Who will receive the order?'**
  String get checkoutReceiverTitle;

  /// Receiver sheet: button that keeps the name and phone and carries on to payment.
  ///
  /// In en, this message translates to:
  /// **'Save and proceed'**
  String get checkoutSaveAndProceed;

  /// Payment screen: title.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get checkoutPayTitle;

  /// Payment screen: line under the title. The amount is already formatted.
  ///
  /// In en, this message translates to:
  /// **'Bill total: {amount}'**
  String checkoutBillTotal(String amount);

  /// Payment screen: button that pays online and places the order.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get checkoutPayNow;

  /// Cart: the bottom button that goes on to choosing how to pay.
  ///
  /// In en, this message translates to:
  /// **'Proceed To Pay'**
  String get cartProceedToPay;

  /// Cart: small caps label under the amount on the bottom button.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get cartTotalLabel;

  /// Cart: the bottom button when no delivery address is known yet.
  ///
  /// In en, this message translates to:
  /// **'Select address to proceed'**
  String get cartSelectAddress;

  /// Cart: bottom bar line above the address. The label is Home, Work or Other.
  ///
  /// In en, this message translates to:
  /// **'Delivering to {label}'**
  String cartDeliveringTo(String label);

  /// Cart: the bill's last line, what the customer will pay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get cartToPay;

  /// Cart: heading of the coupon card.
  ///
  /// In en, this message translates to:
  /// **'Apply coupon'**
  String get cartCoupons;

  /// Cart: heading of the cancellation note.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get cartCancellationTitle;

  /// Cart: the cancellation note under the bill.
  ///
  /// In en, this message translates to:
  /// **'Orders cannot be cancelled once packed for delivery. In case of unexpected delays, a refund will be provided, if applicable.'**
  String get cartCancellationBody;

  /// Variant sheet: title over the list of sizes a product comes in.
  ///
  /// In en, this message translates to:
  /// **'Choose Variant'**
  String get variantSheetTitle;

  /// Variant sheet: shown when the list of sizes failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the sizes for this product.'**
  String get variantSheetFailed;

  /// Variant sheet: button that loads the sizes again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get variantSheetRetry;

  /// Seller dashboard: tile with the money earned on delivered orders.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get sellerDashBalance;

  /// Seller dashboard: tile counting products with no stock left.
  ///
  /// In en, this message translates to:
  /// **'Sold out products'**
  String get sellerDashSoldOut;

  /// Seller dashboard: tile counting products with five or fewer left.
  ///
  /// In en, this message translates to:
  /// **'Low stock products'**
  String get sellerDashLowStockTile;

  /// Seller dashboard: heading of the weekly sales chart.
  ///
  /// In en, this message translates to:
  /// **'Sales in the last 7 days'**
  String get sellerDashWeekSales;

  /// Seller dashboard: the week's total under the chart heading. The amount is already formatted.
  ///
  /// In en, this message translates to:
  /// **'{amount} this week'**
  String sellerDashWeekTotal(String amount);

  /// Seller dashboard: heading of the per-category product count.
  ///
  /// In en, this message translates to:
  /// **'Products by category'**
  String get sellerDashCategoryCount;

  /// Add product: heading of the section listing the sizes the product is sold in.
  ///
  /// In en, this message translates to:
  /// **'Sizes (variants)'**
  String get addProductVariantsTitle;

  /// Add product: explanation under the sizes heading.
  ///
  /// In en, this message translates to:
  /// **'Sell this product in more sizes, like 500 GM and 1 KG. Add each size buyers can choose, including the main one.'**
  String get addProductVariantsHelp;

  /// Add product: shown when the saved sizes failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load this product\'s sizes. Open it again to edit them.'**
  String get addProductVariantsFailed;

  /// Add product: label of a size's name field.
  ///
  /// In en, this message translates to:
  /// **'Size, e.g. 500 GM'**
  String get addProductVariantName;

  /// Add product: button that adds another size.
  ///
  /// In en, this message translates to:
  /// **'Add a size'**
  String get addProductVariantAdd;

  /// Add product: tooltip of the button that removes a size.
  ///
  /// In en, this message translates to:
  /// **'Remove this size'**
  String get addProductVariantRemove;

  /// Seller orders: hint in the search box.
  ///
  /// In en, this message translates to:
  /// **'Search order ID, item or address'**
  String get sellerOrdersSearchHint;

  /// Seller orders: button that picks a date range.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get sellerOrdersDates;

  /// Seller orders: tooltip of the button that removes the date range.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get sellerOrdersClearDates;

  /// Seller returns: screen title.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get sellerReturnsTitle;

  /// Seller returns: shown while the list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading returns…'**
  String get sellerReturnsLoading;

  /// Seller returns: shown when the list failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load returns'**
  String get sellerReturnsLoadFailed;

  /// Seller returns: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No return requests'**
  String get sellerReturnsEmptyTitle;

  /// Seller returns: empty state body.
  ///
  /// In en, this message translates to:
  /// **'When a customer asks to return an item from one of your orders, it shows up here.'**
  String get sellerReturnsEmptyBody;

  /// Seller returns: the order a request is for.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String sellerReturnsOrder(String id);

  /// Seller returns: the refund amount. Already formatted.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount}'**
  String sellerReturnsRefund(String amount);

  /// Seller more: menu item that opens the return requests.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get sellerMoreReturns;

  /// Seller more: subtitle of the Returns item.
  ///
  /// In en, this message translates to:
  /// **'Return requests on your orders'**
  String get sellerMoreReturnsSub;

  /// Seller products: menu item and dialog title for setting how many are in stock.
  ///
  /// In en, this message translates to:
  /// **'Update stock'**
  String get sellerProductsStockTitle;

  /// Seller products: stock dialog cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sellerProductsStockCancel;

  /// Seller products: stock dialog save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sellerProductsStockSave;

  /// Seller products: confirmation after the stock was saved.
  ///
  /// In en, this message translates to:
  /// **'Stock set to {count}'**
  String sellerProductsStockSaved(int count);

  /// Seller products: shown when saving the stock failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the stock. Try again.'**
  String get sellerProductsStockFailed;

  /// Rider home: greeting in the header.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String deliveryDashHi(String name);

  /// Rider home: the on-duty switch while on.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get deliveryDashOnlinePill;

  /// Rider home: the on-duty switch while off.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get deliveryDashOfflinePill;

  /// Rider home: heading over the day's four figures.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Performance'**
  String get deliveryDashTodayPerformance;

  /// Rider home: tile with what was earned today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get deliveryDashTodayEarnings;

  /// Rider home: tile with the runs delivered today.
  ///
  /// In en, this message translates to:
  /// **'Orders Delivered'**
  String get deliveryDashOrdersDelivered;

  /// Rider home: tile with cash taken on today's cash-on-delivery orders.
  ///
  /// In en, this message translates to:
  /// **'Cash Collected'**
  String get deliveryDashCashCollected;

  /// Rider home: tile with the orders the rider had today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get deliveryDashTodayOrders;

  /// Rider home: heading over the all-time figures.
  ///
  /// In en, this message translates to:
  /// **'Delivery Overview'**
  String get deliveryDashOverview;

  /// Rider home: runs in hand, and the heading of the status chart.
  ///
  /// In en, this message translates to:
  /// **'Active orders'**
  String get deliveryDashActiveOrders;

  /// Rider home: earned and not yet paid out.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get deliveryDashAvailableBalance;

  /// Rider home: cash taken on cash-on-delivery orders.
  ///
  /// In en, this message translates to:
  /// **'Cash in Hand'**
  String get deliveryDashCashInHand;

  /// Rider home: every order the rider has had.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get deliveryDashTotalOrders;

  /// Rider home: chart legend.
  ///
  /// In en, this message translates to:
  /// **'Out For Delivery'**
  String get deliveryDashOutForDelivery;

  /// Rider home: chart legend.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryDashDeliveredLegend;

  /// Rider home: chart legend.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get deliveryDashCancelledLegend;

  /// Rider home: figure under the chart.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get deliveryDashTotalEarnedShort;

  /// Rider bottom navigation: the earnings tab.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get deliveryDashNavEarnings;

  /// Rider home: heading over the earnings chart.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get deliveryDashEarningsChart;

  /// Rider home: chart period choice.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get deliveryDashLast7;

  /// Rider home: chart period choice.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get deliveryDashLast30;

  /// Rider home: heading over the all-time delivery figures and rates.
  ///
  /// In en, this message translates to:
  /// **'Delivery Performance'**
  String get deliveryDashPerformance;

  /// Rider home: all orders, in the performance card.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deliveryDashPerfTotal;

  /// Rider home: orders in hand, in the performance card.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deliveryDashPerfActive;

  /// Rider home: share of orders delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivery Success Rate'**
  String get deliveryDashSuccessRate;

  /// Rider home: share of orders cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Rate'**
  String get deliveryDashCancelRate;

  /// Rider home: share of orders still in hand.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get deliveryDashInProgress;

  /// Rider deliveries: chip that shows every run.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deliveryOrdersChipAll;

  /// Rider deliveries: runs waiting at a store, and their status.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get deliveryOrdersReadyForPickup;

  /// Rider deliveries: hint in the search box.
  ///
  /// In en, this message translates to:
  /// **'Search order, item or address'**
  String get deliveryOrdersSearchHint;

  /// Rider deliveries: the order's short number.
  ///
  /// In en, this message translates to:
  /// **'#{id}'**
  String deliveryOrdersNumber(String id);

  /// Rider deliveries: the size under an item.
  ///
  /// In en, this message translates to:
  /// **'Pack Size: {size}'**
  String deliveryOrdersPackSize(String size);

  /// Rider deliveries: items not listed on the card.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{+1 more item} other{+{count} more items}}'**
  String deliveryOrdersMoreItems(int count);

  /// Rider deliveries: cash on delivery, not yet collected.
  ///
  /// In en, this message translates to:
  /// **'Pay via COD'**
  String get deliveryOrdersPayCod;

  /// Rider deliveries: cash on delivery, collected.
  ///
  /// In en, this message translates to:
  /// **'Paid via COD'**
  String get deliveryOrdersPaidCod;

  /// Rider deliveries: paid before delivery.
  ///
  /// In en, this message translates to:
  /// **'Paid online'**
  String get deliveryOrdersPaidOnline;

  /// Rider deliveries: the cash to take at the door.
  ///
  /// In en, this message translates to:
  /// **'Collect from Customer'**
  String get deliveryOrdersCollect;

  /// Rider deliveries: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No orders here'**
  String get deliveryOrdersEmptyTitle;

  /// Rider deliveries: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Orders ready for pickup, on the way and delivered show up here.'**
  String get deliveryOrdersEmptyBody;

  /// Rider earnings: what was earned today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earning'**
  String get deliveryEarningsToday;

  /// Rider earnings: earned and not yet paid out.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get deliveryEarningsWallet;

  /// Rider earnings: earned since Monday.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get deliveryEarningsWeek;

  /// Rider earnings: what the shop has paid out.
  ///
  /// In en, this message translates to:
  /// **'Settlement History'**
  String get deliveryEarningsSettled;

  /// Rider earnings: heading over the list of earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings history'**
  String get deliveryEarningsHistory;

  /// Rider: screen and tile for the cash taken on cash-on-delivery orders.
  ///
  /// In en, this message translates to:
  /// **'Cash Collection'**
  String get deliveryCashTitle;

  /// Rider cash: shown while the list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading cash collection…'**
  String get deliveryCashLoading;

  /// Rider cash: shown when the list failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load cash collection'**
  String get deliveryCashLoadFailed;

  /// Rider cash: tile with today's cash total.
  ///
  /// In en, this message translates to:
  /// **'Collected today'**
  String get deliveryCashToday;

  /// Rider cash: tile with the total cash collected.
  ///
  /// In en, this message translates to:
  /// **'Collected in all'**
  String get deliveryCashTotal;

  /// Rider cash: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No cash collected yet'**
  String get deliveryCashEmptyTitle;

  /// Rider cash: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Cash-on-delivery orders you deliver show up here with the amount you collected.'**
  String get deliveryCashEmptyBody;

  /// Rider cash: the order a collection was for.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String deliveryCashOrder(String id);

  /// Rider profile: button that opens Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deliveryProfileEdit;

  /// Rider profile: heading of the support group.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get deliveryProfileSupport;

  /// Rider profile: row that opens support.
  ///
  /// In en, this message translates to:
  /// **'Chat with Support'**
  String get deliveryProfileChat;

  /// Rider profile: heading and folded row holding the policies.
  ///
  /// In en, this message translates to:
  /// **'Help & Policies'**
  String get deliveryProfilePolicies;

  /// Rider profile: privacy policy row.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get deliveryProfilePrivacy;

  /// Rider profile: terms row.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get deliveryProfileTerms;

  /// Rider profile: heading of the settings and log out group.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get deliveryProfileAccount;

  /// Rider profile: row and screen title for settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get deliveryProfileSettings;

  /// Rider settings: group heading.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get deliverySettingsGeneral;

  /// Rider settings: opens the notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get deliverySettingsNotifications;

  /// Rider settings: row and dialog title for a new password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get deliverySettingsPassword;

  /// Rider settings: first password field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get deliverySettingsNewPassword;

  /// Rider settings: second password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get deliverySettingsConfirmPassword;

  /// Rider settings: password too short.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get deliverySettingsTooShort;

  /// Rider settings: passwords differ.
  ///
  /// In en, this message translates to:
  /// **'The two passwords don\'t match'**
  String get deliverySettingsMismatch;

  /// Rider settings: after the password was saved.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get deliverySettingsPasswordSaved;

  /// Rider settings and edit profile: cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deliverySettingsCancel;

  /// Rider settings and edit profile: save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get deliverySettingsSave;

  /// Rider settings: row and dialog title for closing the account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deliverySettingsDelete;

  /// Rider settings: why deleting goes through support.
  ///
  /// In en, this message translates to:
  /// **'A delivery partner account has runs and payouts linked to it, so it is closed by our support team. Contact support and they will close it for you.'**
  String get deliverySettingsDeleteBody;

  /// Rider settings: button that opens Contact Us.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get deliverySettingsContact;

  /// Rider edit profile: title.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get deliveryEditTitle;

  /// Rider edit profile: subtitle on step one.
  ///
  /// In en, this message translates to:
  /// **'Update your personal details'**
  String get deliveryEditStepOne;

  /// Rider edit profile: subtitle on step two.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle and documents'**
  String get deliveryEditStepTwo;

  /// Rider edit profile: shown while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get deliveryEditLoading;

  /// Rider edit profile: shown when loading failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile'**
  String get deliveryEditLoadFailed;

  /// Rider edit profile: name field.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get deliveryEditName;

  /// Rider edit profile: email (read-only).
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get deliveryEditEmail;

  /// Rider edit profile: date of birth field.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get deliveryEditBirth;

  /// Rider edit profile: date of birth before one is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get deliveryEditBirthHint;

  /// Rider edit profile: city field.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get deliveryEditCity;

  /// Rider edit profile: mobile field.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get deliveryEditMobile;

  /// Rider edit profile: address field.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get deliveryEditAddress;

  /// Rider edit profile: vehicle type choice.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get deliveryEditVehicle;

  /// Rider edit profile: vehicle type.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get deliveryEditVehicleBike;

  /// Rider edit profile: vehicle type.
  ///
  /// In en, this message translates to:
  /// **'Scooter'**
  String get deliveryEditVehicleScooter;

  /// Rider edit profile: vehicle type.
  ///
  /// In en, this message translates to:
  /// **'EV Scooter'**
  String get deliveryEditVehicleEv;

  /// Rider edit profile: vehicle type.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get deliveryEditVehicleBicycle;

  /// Rider edit profile: vehicle number field.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get deliveryEditVehicleNumber;

  /// Rider edit profile: licence number field.
  ///
  /// In en, this message translates to:
  /// **'Driving Licence Number'**
  String get deliveryEditLicence;

  /// Rider edit profile: heading over the documents link.
  ///
  /// In en, this message translates to:
  /// **'National ID & Driving Licence'**
  String get deliveryEditDocuments;

  /// Rider edit profile: opens the documents screen.
  ///
  /// In en, this message translates to:
  /// **'Upload or change your ID and licence photos'**
  String get deliveryEditDocumentsBody;

  /// Rider edit profile: goes to step two.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get deliveryEditNext;

  /// Rider edit profile: goes back to step one.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deliveryEditBack;

  /// Rider edit profile: after saving.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get deliveryEditSaved;

  /// Rider edit profile: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Try again.'**
  String get deliveryEditSaveFailed;

  /// Support chat: title.
  ///
  /// In en, this message translates to:
  /// **'Chat with Support'**
  String get supportChatTitle;

  /// Support chat: shown while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your chat…'**
  String get supportChatLoading;

  /// Support chat: shown when loading failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the chat'**
  String get supportChatLoadFailed;

  /// Support chat: empty state title.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get supportChatEmptyTitle;

  /// Support chat: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Send us a message and our team will reply here.'**
  String get supportChatEmptyBody;

  /// Support chat: hint in the message box.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get supportChatHint;

  /// Support chat: sending failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the message. Try again.'**
  String get supportChatSendFailed;

  /// Support chat: separator for today's messages.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get supportChatToday;

  /// Support chat: separator for yesterday's messages.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get supportChatYesterday;

  /// Admin: title of the support inbox and its moderation tile.
  ///
  /// In en, this message translates to:
  /// **'Support chats'**
  String get adminSupportTitle;

  /// Admin moderation: subtitle of the support tile.
  ///
  /// In en, this message translates to:
  /// **'Messages from customers, sellers and riders'**
  String get adminSupportSub;

  /// Admin support: shown while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading support chats…'**
  String get adminSupportLoading;

  /// Admin support: shown when loading failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load support chats'**
  String get adminSupportLoadFailed;

  /// Admin support: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get adminSupportEmptyTitle;

  /// Admin support: empty state body.
  ///
  /// In en, this message translates to:
  /// **'When someone writes to support, their chat shows up here.'**
  String get adminSupportEmptyBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
