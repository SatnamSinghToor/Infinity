// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navCart => 'Cart';

  @override
  String get navProfile => 'Profile';

  @override
  String get cartTitle => 'My Cart';

  @override
  String cartStockLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count in stock',
      one: 'Only 1 in stock',
    );
    return '$_temp0';
  }

  @override
  String cartDeliveryIn(String eta) {
    return 'Delivery in $eta';
  }

  @override
  String get cartDeliverySoon => 'Delivery today';

  @override
  String cartShipment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shipment of $count items',
      one: 'Shipment of 1 item',
    );
    return '$_temp0';
  }

  @override
  String get cartMoveToWishlist => 'Move to wishlist';

  @override
  String get cartMovedToWishlist => 'Moved to your wishlist';

  @override
  String get cartYouMightLike => 'You might also like';

  @override
  String productOnlyLeft(int count) {
    return 'Only $count left';
  }

  @override
  String get cartSearchHint => 'Search in your cart';

  @override
  String get cartNoMatch => 'No item in your cart matches that.';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Add items from the store to get started';

  @override
  String get cartBrowse => 'Browse Products';

  @override
  String get cartLoadFailed => 'Couldn\'t load your cart';

  @override
  String get cartSyncFailed =>
      'Some changes could not reach the server. Your cart on this phone is right — resend it before you check out.';

  @override
  String get cartSyncRetry => 'Resend';

  @override
  String get cartClear => 'Clear cart';

  @override
  String get cartClearTitle => 'Clear cart?';

  @override
  String get cartClearBody => 'All items will be removed from your cart.';

  @override
  String get cartKeep => 'Keep';

  @override
  String get cartClearAction => 'Clear';

  @override
  String get cartBillDetails => 'Bill Details';

  @override
  String cartYouSave(String amount) {
    return 'You\'re saving $amount on this order';
  }

  @override
  String cartFreeDeliveryShort(String amount) {
    return 'Add $amount more for FREE delivery';
  }

  @override
  String get cartFreeDeliveryUnlocked => 'Yay! You get FREE delivery';

  @override
  String cartItemsCount(int count) {
    return 'Items ($count)';
  }

  @override
  String get cartDeliveryFee => 'Delivery fee';

  @override
  String get cartFree => 'Free';

  @override
  String get cartLoginToCheckout => 'Login to Checkout';

  @override
  String get wishlistTitle => 'My Wishlist';

  @override
  String get wishlistLoadFailed => 'Couldn\'t load your wishlist';

  @override
  String get wishlistClearTitle => 'Clear Wishlist?';

  @override
  String get wishlistClearBody => 'Remove all items from your wishlist?';

  @override
  String get wishlistCancel => 'Cancel';

  @override
  String get wishlistClear => 'Clear';

  @override
  String get wishlistEmptyTitle => 'Your wishlist is empty';

  @override
  String get wishlistEmptyBody =>
      'Tap the heart icon on products to save them here.';

  @override
  String get wishlistBrowse => 'Browse Products';

  @override
  String wishlistItemsCount(int count) {
    return '$count items';
  }

  @override
  String wishlistAddedToCart(int count) {
    return '$count items added to cart!';
  }

  @override
  String get wishlistAddAll => 'ADD ALL TO CART';

  @override
  String get ordersTitle => 'Your Orders';

  @override
  String get ordersLoadFailed => 'Couldn\'t load your orders';

  @override
  String get ordersEmptyTitle => 'No orders yet!';

  @override
  String get ordersEmptyBody => 'Start shopping to place your first order.';

  @override
  String get ordersTotal => 'Total';

  @override
  String get walletTitle => 'My Wallet';

  @override
  String get walletBalanceLabel => 'Available Balance';

  @override
  String get walletHistoryTitle => 'Transaction History';

  @override
  String get walletLoadFailed => 'Couldn\'t load your wallet';

  @override
  String get walletEmpty => 'No transactions yet';

  @override
  String get paymentMethodsTitle => 'Payment Methods';

  @override
  String get paymentMethodsLoadFailed => 'Couldn\'t load your payment methods';

  @override
  String get paymentMethodsAddTitle => 'Add Payment Method';

  @override
  String get paymentMethodsUpi => 'UPI';

  @override
  String get paymentMethodsCard => 'Card';

  @override
  String get paymentMethodsUpiLabel => 'UPI app name';

  @override
  String get paymentMethodsCardLabel => 'Card name';

  @override
  String get paymentMethodsUpiLabelHint => 'e.g. Google Pay';

  @override
  String get paymentMethodsCardLabelHint => 'e.g. HDFC Bank';

  @override
  String get paymentMethodsUpiDetail => 'UPI ID';

  @override
  String get paymentMethodsCardDetail => 'Card last 4 digits';

  @override
  String get paymentMethodsUpiDetailHint => 'name@upi';

  @override
  String get paymentMethodsCardDetailHint => '•••• 1234';

  @override
  String get paymentMethodsCancel => 'Cancel';

  @override
  String get paymentMethodsSave => 'Save';

  @override
  String get paymentMethodsEmpty => 'No payment methods saved';

  @override
  String get paymentMethodsDefaultBadge => 'DEFAULT';

  @override
  String get paymentMethodsSetDefault => 'Set default';

  @override
  String get paymentMethodsSetDefaultFailed =>
      'Couldn\'t set this as your default. Check your connection and try again.';

  @override
  String get paymentMethodsDeleteFailed =>
      'Couldn\'t remove this payment method. Check your connection and try again.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsLoadFailed => 'Couldn\'t load your notifications';

  @override
  String get notificationsUpdateFailed =>
      'Couldn\'t update that. Please try again.';

  @override
  String get notificationsUndo => 'Undo';

  @override
  String get notificationsArchived => 'Notification archived';

  @override
  String get notificationsUnarchived => 'Moved back to inbox';

  @override
  String get notificationsDeleted => 'Notification deleted';

  @override
  String get notificationsAllRead => 'All marked as read';

  @override
  String notificationsArchiveAllDone(int count) {
    return '$count archived';
  }

  @override
  String get notificationsClearAllTitle => 'Clear all?';

  @override
  String get notificationsClearArchiveTitle => 'Clear archive?';

  @override
  String notificationsClearConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications',
      one: '1 notification',
    );
    return 'This permanently deletes $_temp0. It can\'t be undone.';
  }

  @override
  String get notificationsCancel => 'Cancel';

  @override
  String get notificationsDelete => 'Delete';

  @override
  String get notificationsCleared => 'Cleared';

  @override
  String get notificationsMore => 'More';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsArchiveAll => 'Archive all';

  @override
  String get notificationsClearAll => 'Clear all';

  @override
  String get notificationsClearArchive => 'Clear archive';

  @override
  String get notificationsInbox => 'Inbox';

  @override
  String notificationsInboxCount(int count) {
    return 'Inbox ($count)';
  }

  @override
  String get notificationsArchivedTab => 'Archived';

  @override
  String get notificationsSwipeHintInbox =>
      'Swipe right to archive  •  left to delete';

  @override
  String get notificationsSwipeHintArchive =>
      'Swipe right to move back to inbox  •  left to delete';

  @override
  String get notificationsMoveToInbox => 'Move to inbox';

  @override
  String get notificationsArchive => 'Archive';

  @override
  String get notificationsEmptyArchivedTitle => 'Nothing archived';

  @override
  String get notificationsEmptyTitle => 'You\'re all caught up';

  @override
  String get notificationsEmptyArchivedBody =>
      'Archived notifications show up here.';

  @override
  String get notificationsEmptyBody => 'New notifications will show up here.';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get notificationsOptions => 'Options';

  @override
  String get notificationsMarkRead => 'Mark as read';

  @override
  String get notificationsMarkUnread => 'Mark as unread';

  @override
  String get brandsTitle => 'Shop by Brand';

  @override
  String get brandsLoadFailed => 'Couldn\'t load the brands';

  @override
  String get brandsEmpty => 'No brands available yet.';

  @override
  String get orderSupportTitle => 'Order Help';

  @override
  String get orderSupportLoadFailed => 'Couldn\'t load this order\'s tickets';

  @override
  String get orderSupportRequestReturn => 'Request a Return';

  @override
  String get orderSupportReportProblem => 'Report a Problem';

  @override
  String get orderSupportRequestReturnButton => 'Request Return';

  @override
  String get orderSupportReason => 'Reason';

  @override
  String get orderSupportDescription => 'Description';

  @override
  String get orderSupportCancel => 'Cancel';

  @override
  String get orderSupportSubmit => 'Submit';

  @override
  String get orderSupportSubmitted => 'Your request has been submitted.';

  @override
  String get orderSupportSubmitFailed =>
      'Couldn\'t submit this request. It may be outside the eligible window.';

  @override
  String get orderSupportIssuesHeading => 'Reported Issues';

  @override
  String get orderSupportReturnsHeading => 'Return Requests';

  @override
  String get orderSupportEmpty =>
      'No issues or return requests for this order yet.';

  @override
  String get helpAboutTitle => 'About Us';

  @override
  String get helpAboutDugguHeading => 'duggu';

  @override
  String get helpAboutDugguBody =>
      'Duggu brings groceries, daily needs and festival shopping from stores near you to your door, fast.';

  @override
  String get helpAboutStoresHeading => 'Local stores';

  @override
  String get helpAboutStoresBody =>
      'Every order is fulfilled by a real store close to your address. The delivery time you see is worked out from where you are and where the nearest store is.';

  @override
  String get helpAboutNeighbourhoodsHeading => 'Made for neighbourhoods';

  @override
  String get helpAboutNeighbourhoodsBody =>
      'Sellers list their own products and prices, delivery partners bring them to you, and you pay how you like: cash on delivery, online or from your Duggu wallet.';

  @override
  String get helpPoliciesTitle => 'Policies';

  @override
  String get helpPolicyPrivacyHeading => 'Privacy';

  @override
  String get helpPolicyPrivacyBody =>
      'We keep the details you give us (name, email, phone number, delivery addresses) and your order history so we can deliver your orders and show them back to you. Your location is used only when you choose \"Use current location\" or set an address on the map.';

  @override
  String get helpPolicyPaymentsHeading => 'Payments';

  @override
  String get helpPolicyPaymentsBody =>
      'Online payments are handled by Razorpay. Duggu never sees or stores your card or UPI details.';

  @override
  String get helpPolicyDeliveryHeading => 'Delivery';

  @override
  String helpPolicyDeliveryBody(String fee, String threshold) {
    return 'A delivery fee of $fee applies to each store\'s part of an order under $threshold; above that it is free.';
  }

  @override
  String get helpPolicyRefundsHeading => 'Cancellations and refunds';

  @override
  String get helpPolicyRefundsBody =>
      'An order can be cancelled from My Orders while the store has not sent it out. Money you paid from your Duggu wallet goes back to the wallet.';

  @override
  String get helpPolicyReturnsHeading => 'Returns';

  @override
  String get helpPolicyReturnsBody =>
      'Delivered orders can be reported or returned from the order\'s page within 10 days of delivery.';

  @override
  String get helpTermsTitle => 'Terms & Conditions';

  @override
  String get helpTermsUsingHeading => 'Using Duggu';

  @override
  String get helpTermsUsingBody =>
      'You need an account to place orders. Please keep your login private and give correct details, especially your delivery address and phone number.';

  @override
  String get helpTermsPricesHeading => 'Prices and stock';

  @override
  String get helpTermsPricesBody =>
      'Prices and availability are set by each store and are checked again when you place the order. If something is out of stock the order cannot be placed as it is.';

  @override
  String get helpTermsCouponsHeading => 'Coupons and wallet';

  @override
  String get helpTermsCouponsBody =>
      'A coupon can be used once per account and only above its minimum order value. Wallet money can only be spent on Duggu orders.';

  @override
  String get helpTermsFairUseHeading => 'Fair use';

  @override
  String get helpTermsFairUseBody =>
      'We may limit or close accounts that misuse offers, the wallet or referral bonuses.';

  @override
  String get helpFaqTitle => 'FAQ';

  @override
  String get helpFaqDeliveryTimeQuestion =>
      'How is the delivery time worked out?';

  @override
  String get helpFaqDeliveryTimeAnswer =>
      'From your delivery address and the nearest store that can serve you. Set your address at the top of the home page to see it.';

  @override
  String get helpFaqChargesQuestion => 'What are the delivery charges?';

  @override
  String helpFaqChargesAnswer(String fee, String threshold) {
    return '$fee for each store\'s part of your order, and free when that part is $threshold or more.';
  }

  @override
  String get helpFaqPayQuestion => 'How can I pay?';

  @override
  String get helpFaqPayAnswer =>
      'Cash on delivery, online (UPI and cards) or from your Duggu wallet. You can use wallet money together with either of the other two.';

  @override
  String get helpFaqCouponsQuestion => 'Can I use more than one coupon?';

  @override
  String get helpFaqCouponsAnswer =>
      'One coupon per order, and each coupon can be used once per account.';

  @override
  String get helpFaqCancelQuestion => 'How do I cancel an order?';

  @override
  String get helpFaqCancelAnswer =>
      'Open it from Orders. If the store has not sent it out yet you will see the option to cancel. Wallet money you used is refunded to the wallet.';

  @override
  String get helpFaqWrongItemQuestion => 'Something was wrong with my order';

  @override
  String get helpFaqWrongItemAnswer =>
      'Open the order from Orders and report the problem or ask for a return. Returns can be asked for within 10 days of delivery.';

  @override
  String get helpFaqReferralQuestion => 'How does the referral bonus work?';

  @override
  String helpFaqReferralAnswer(String amount) {
    return 'When a friend signs up with your referral code, you both get $amount in your wallet.';
  }

  @override
  String get helpFaqMissingProductQuestion =>
      'A product I want is not in the store';

  @override
  String get helpFaqMissingProductAnswer =>
      'Ask for it under Profile, Product Requests.';

  @override
  String get helpContactTitle => 'Contact Us';

  @override
  String get helpContactIntro =>
      'Tell us what you need help with and we will get back to you.';

  @override
  String get helpContactSubject => 'Subject';

  @override
  String get helpContactMessage => 'Message';

  @override
  String get helpContactSend => 'Send';

  @override
  String get helpContactSent => 'Thanks, we got your message.';

  @override
  String get helpSending => 'Sending...';

  @override
  String get helpSendFailed => 'Could not send. Try again.';

  @override
  String get helpRequestsTitle => 'Product Requests';

  @override
  String get helpRequestsIntro =>
      'Cannot find something? Tell us what you would like to see in the store.';

  @override
  String get helpRequestsName => 'Product name';

  @override
  String get helpRequestsDetails => 'Brand, size or anything else (optional)';

  @override
  String get helpRequestsSend => 'Request product';

  @override
  String get helpRequestsSent => 'Request sent.';

  @override
  String get helpRequestsLoadFailed => 'Couldn\'t load your requests.';

  @override
  String get helpRequestsMine => 'Your requests';

  @override
  String get helpRequestDone => 'Done';

  @override
  String get helpRequestOpen => 'Open';

  @override
  String get helpRateTitle => 'How is your experience with Duggu?';

  @override
  String get helpRateNote => 'Tell us more (optional)';

  @override
  String get helpRateSubmit => 'Submit';

  @override
  String get helpRateThanks => 'Thank you for rating Duggu.';

  @override
  String get helpShareMessage =>
      'Try Duggu: groceries and daily needs from stores near you, delivered fast.';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileAvatarFailed => 'Could not update your photo.';

  @override
  String get profileRoleSwitchFailed => 'Could not switch role. Try again.';

  @override
  String get profileBecomeSeller => 'Become a Seller';

  @override
  String get profileBusinessName => 'Business name';

  @override
  String get profileOwnerName => 'Owner name';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSubmit => 'Submit';

  @override
  String get profileBecomeDelivery => 'Become a Delivery Partner';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileVehicleType => 'Vehicle type';

  @override
  String get profileVehicleBike => 'Bike';

  @override
  String get profileVehicleScooter => 'Scooter';

  @override
  String get profileVehicleBicycle => 'Bicycle';

  @override
  String get profileVehicleEvScooter => 'EV Scooter';

  @override
  String get profileStale => 'Couldn\'t load your account details.';

  @override
  String get profileSectionPersonal => 'Personal Data';

  @override
  String get profileSectionSettings => 'App Settings';

  @override
  String get profileSectionHelp => 'Help & Support';

  @override
  String get profileSectionAbout => 'About & Community';

  @override
  String get profileSectionWork => 'Work with Duggu';

  @override
  String get profileMyOrders => 'My Orders';

  @override
  String get profileAddresses => 'Addresses';

  @override
  String get profileMyWallet => 'My Wallet';

  @override
  String get profilePaymentMethods => 'Payment Methods';

  @override
  String get profileWishlist => 'Wishlist';

  @override
  String get profileChangeTheme => 'Change Theme';

  @override
  String get profileContactUs => 'Contact Us';

  @override
  String get profileFaq => 'FAQ';

  @override
  String get profileProductRequests => 'Product Requests';

  @override
  String get profilePolicies => 'Policies';

  @override
  String get profileTerms => 'Terms & Conditions';

  @override
  String get profileNotifications => 'Notification';

  @override
  String get profileAbout => 'About Us';

  @override
  String get profileRateUs => 'Rate Us';

  @override
  String get profileShareApp => 'Share App';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String get profileDeleteBody =>
      'Your name, phone, addresses, cart, wishlist and saved payment methods will be removed and you won\'t be able to sign in again. Past orders stay with the store, without your address. This can\'t be undone.';

  @override
  String get profileDeleteConfirm => 'Delete';

  @override
  String get profileDeleteKeep => 'Keep account';

  @override
  String get profileDeleteActiveOrders =>
      'You have an order on its way. Delete your account once it\'s delivered or cancelled.';

  @override
  String get profileDeleteFailed =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get profileDeleted => 'Your account has been deleted.';

  @override
  String get profileWelcomeName => 'Welcome';

  @override
  String get profileWelcomeGuest => 'Welcome to duggu';

  @override
  String get profileLogin => 'Login';

  @override
  String get profileReferralFailed =>
      'Couldn\'t load your friends code — tap to retry';

  @override
  String profileReferralCode(String code) {
    return 'Friends Code: $code';
  }

  @override
  String get profileReferralCopied => 'Code copied. Share it with a friend.';

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get orderDetailNotFoundTitle => 'Order Not Found';

  @override
  String get orderDetailLoading => 'Loading this order…';

  @override
  String get orderDetailLoadFailed => 'Couldn\'t load this order';

  @override
  String get orderDetailLoadFailedBody =>
      'Check your connection and try again — the order itself is safe.';

  @override
  String get orderDetailNotFound => 'Order not found';

  @override
  String get orderDetailNotFoundBody =>
      'No order with this number belongs to this account. If you ordered with a different phone number, sign in with that one.';

  @override
  String get orderDetailTrack => 'Track Order';

  @override
  String get orderDetailSectionInfo => 'Order Information';

  @override
  String get orderDetailOrderId => 'Order ID';

  @override
  String get orderDetailDate => 'Date';

  @override
  String get orderDetailStatusLabel => 'Status';

  @override
  String get orderDetailSectionAddress => 'Delivery Address';

  @override
  String get orderDetailName => 'Name';

  @override
  String get orderDetailPhone => 'Phone';

  @override
  String get orderDetailAddress => 'Address';

  @override
  String get orderDetailSectionItems => 'Order Items';

  @override
  String get orderDetailRatePartner => 'Rate Delivery Partner';

  @override
  String get orderDetailSectionPayment => 'Payment Summary';

  @override
  String get orderDetailSubtotal => 'Subtotal';

  @override
  String get orderDetailDeliveryFee => 'Delivery Fee';

  @override
  String get orderDetailFree => 'FREE';

  @override
  String get orderDetailWalletApplied => 'Wallet Applied';

  @override
  String get orderDetailTip => 'Delivery partner tip';

  @override
  String get orderDetailTotal => 'Total';

  @override
  String get orderDetailSupport => 'Report a Problem / Request Return';

  @override
  String get orderDetailOrderAgain => 'Order again';

  @override
  String get orderDetailInvoice => 'Download invoice';

  @override
  String get orderDetailInvoiceFailed =>
      'Couldn\'t create the invoice. Please try again.';

  @override
  String orderDetailOrderAgainAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added to cart',
      one: '1 item added to cart',
    );
    return '$_temp0';
  }

  @override
  String orderDetailOrderAgainSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are out of stock and were left out',
      one: '1 item is out of stock and was left out',
    );
    return '$_temp0';
  }

  @override
  String get orderDetailOrderAgainNone =>
      'None of these items are in stock right now.';

  @override
  String get orderDetailViewCart => 'View cart';

  @override
  String get orderDetailCancelOrder => 'Cancel Order';

  @override
  String orderDetailStatusWith(String status) {
    return 'Order $status';
  }

  @override
  String get orderDetailStepPlaced => 'Placed';

  @override
  String get orderDetailStepPreparing => 'Preparing';

  @override
  String get orderDetailStepOnWay => 'On Way';

  @override
  String get orderDetailStepDelivered => 'Delivered';

  @override
  String orderDetailQty(int count) {
    return 'Qty: $count';
  }

  @override
  String get orderDetailWriteReview => 'Write a Review';

  @override
  String orderDetailReviewTitle(String product) {
    return 'Review $product';
  }

  @override
  String get orderDetailReviewHint => 'Share your experience (optional)';

  @override
  String get orderDetailCancel => 'Cancel';

  @override
  String get orderDetailSubmit => 'Submit';

  @override
  String get orderDetailReviewThanks => 'Thanks for your review!';

  @override
  String get orderDetailReviewFailed =>
      'Couldn\'t save your review. Please try again.';

  @override
  String get orderDetailRateTitle => 'Rate Your Delivery Partner';

  @override
  String get orderDetailRateHint => 'Share your delivery experience (optional)';

  @override
  String get orderDetailRateThanks => 'Thanks for rating your delivery!';

  @override
  String get orderDetailRateFailed =>
      'Couldn\'t save your rating. Please try again.';

  @override
  String get orderDetailCancelTitle => 'Cancel Order?';

  @override
  String get orderDetailCancelQuestion =>
      'Are you sure you want to cancel this order?';

  @override
  String get orderDetailNo => 'No';

  @override
  String orderDetailCancelled(String id) {
    return 'Order $id cancelled';
  }

  @override
  String get orderDetailCancelFailed =>
      'Couldn\'t cancel this order. Please try again.';

  @override
  String get productDetailTitle => 'Product';

  @override
  String get productDetailUnavailable =>
      'This product isn\'t available any more.';

  @override
  String productDetailShare(String name, String price, String app) {
    return '$name for $price on $app';
  }

  @override
  String productDetailSaved(String amount) {
    return '$amount Saved';
  }

  @override
  String get productDetailNotifyFailed => 'Couldn\'t update your notification.';

  @override
  String get productDetailOptionsFailed =>
      'Couldn\'t load the options for this product.';

  @override
  String get productDetailSelectOption => 'Select Option';

  @override
  String get productDetailStoreDetails => 'Store Details';

  @override
  String productDetailStoreProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Products',
      one: '1 Product',
    );
    return '$_temp0';
  }

  @override
  String get productDetailVisitStore => 'Visit Store';

  @override
  String get productDetailReturnable => 'Returnable';

  @override
  String get productDetailCancellable => 'Cancellable';

  @override
  String get productDetailCategory => 'Category';

  @override
  String get productDetailBrand => 'Brand';

  @override
  String get productDetailVeg => 'Veg';

  @override
  String get productDetailNonVeg => 'Non-Veg';

  @override
  String get productDetailAboutItem => 'About this Item';

  @override
  String get productDetailDetailsHeading => 'Product details';

  @override
  String get productDetailNutrition => 'Nutritional Info';

  @override
  String get productDetailTopHighlights => 'Top highlights';

  @override
  String get productDetailProductSpecs => 'Product specifications';

  @override
  String get productDetailAdditionalDetails => 'Additional details';

  @override
  String get productDetailImportantInfo => 'Important information';

  @override
  String get productDetailIngredients => 'Ingredients:';

  @override
  String get productDetailLegalDisclaimer => 'Legal Disclaimer:';

  @override
  String get productDetailLegalDisclaimerBody =>
      'Actual product packaging and materials may carry more or different information than what is shown here. Please read the labels, warnings and directions before using or consuming a product.';

  @override
  String get productDetailNetQuantity => 'Net Quantity';

  @override
  String get productDetailDietType => 'Diet Type';

  @override
  String get productDetailSoldByLabel => 'Sold by';

  @override
  String get productDetailVegProduct => 'This is a Vegetarian product.';

  @override
  String get productDetailNonVegProduct => 'This is a Non-Vegetarian product.';

  @override
  String get productDetailSeeMore => 'See more';

  @override
  String get productDetailSeeLess => 'See less';

  @override
  String get productDetailNotifyMe => 'Notify me when available';

  @override
  String get productDetailNotifyOn => 'We\'ll notify you';

  @override
  String get productDetailAddToCart => 'Add to Cart';

  @override
  String get productDetailGoToCart => 'Go to Cart';

  @override
  String get productDetailReviews => 'Reviews';

  @override
  String get productDetailReviewsFailed => 'Couldn\'t load the reviews.';

  @override
  String get productDetailNoReviews => 'No reviews yet for this product.';

  @override
  String get productDetailSimilar => 'Similar Products';

  @override
  String get productDetailAdminOnSale => 'Admin — this product is on sale';

  @override
  String get productDetailHideFromStore => 'Hide from store';

  @override
  String productDetailHideTitle(String name) {
    return 'Hide \"$name\"?';
  }

  @override
  String get productDetailHideBody =>
      'Customers will no longer see it. The seller keeps the product and can show it again.';

  @override
  String get productDetailCancel => 'Cancel';

  @override
  String get productDetailHide => 'Hide';

  @override
  String get productDetailHideFailed => 'Couldn\'t hide this product.';

  @override
  String get checkoutPayUpi => 'UPI / GPay / PhonePe';

  @override
  String get checkoutPayCard => 'Credit / Debit Card';

  @override
  String get checkoutPayCod => 'Cash on Delivery';

  @override
  String get checkoutCouponInvalid => 'Invalid coupon code';

  @override
  String checkoutCouponMinOrder(String amount) {
    return 'Minimum order of $amount required';
  }

  @override
  String get checkoutCouponFailed => 'Could not apply coupon';

  @override
  String checkoutCouponApplied(String code) {
    return 'Coupon \"$code\" applied';
  }

  @override
  String get checkoutFillDetails => 'Please fill all details';

  @override
  String get checkoutCartSyncFailed =>
      'Could not update your cart. Check your connection and try again.';

  @override
  String get checkoutPaymentFailed => 'Payment failed.';

  @override
  String checkoutPaidOrderFailed(String paymentId) {
    return 'Payment succeeded but the order could not be placed. Contact support with payment ID $paymentId.';
  }

  @override
  String get checkoutPlaceFailed => 'Could not place order. Please try again.';

  @override
  String checkoutFinalTotalCoupon(String total) {
    return 'Final total $total — this coupon could not be applied to the order (a coupon can only be used once per account).';
  }

  @override
  String checkoutFinalTotalChanged(String total, String promised) {
    return 'Final total $total, not $promised as shown before payment.';
  }

  @override
  String get checkoutFullName => 'Full Name';

  @override
  String get checkoutPhoneNumber => 'Phone Number';

  @override
  String get checkoutInstructions => 'Delivery instructions';

  @override
  String get checkoutTipTitle => 'Tip your delivery partner';

  @override
  String get checkoutTipBody => 'Your whole tip goes to the delivery partner.';

  @override
  String get checkoutTipLine => 'Delivery partner tip';

  @override
  String get checkoutInstructionsHint =>
      'Anything else for the delivery partner (optional)';

  @override
  String get checkoutNoteNoBell => 'Don\'t ring the bell';

  @override
  String get checkoutNoteLeaveDoor => 'Leave at the door';

  @override
  String get checkoutNoteCallArrive => 'Call when you arrive';

  @override
  String get checkoutNotePet => 'Pet at home';

  @override
  String get checkoutCouponHint => 'Enter coupon code';

  @override
  String get checkoutApply => 'Apply';

  @override
  String checkoutItemLine(String name, int count) {
    return '$name × $count';
  }

  @override
  String get checkoutCouponDiscount => 'Coupon Discount';

  @override
  String checkoutUseWallet(String amount) {
    return 'Use wallet balance (₹$amount available)';
  }

  @override
  String get checkoutWalletUsed => 'Wallet Used';

  @override
  String get checkoutPlaceOrder => 'PLACE ORDER';

  @override
  String get checkoutSavedAddresses => 'Saved Addresses';

  @override
  String get checkoutDefaultBadge => 'DEFAULT';

  @override
  String get checkoutOrderPlacedTitle => 'Order Placed';

  @override
  String get checkoutSuccess => 'Order Placed Successfully!';

  @override
  String checkoutOrderId(String id) {
    return 'Order ID: $id';
  }

  @override
  String checkoutDeliveringTo(String address) {
    return 'Delivering to: $address';
  }

  @override
  String checkoutExpectedDelivery(String eta) {
    return 'Expected delivery: $eta';
  }

  @override
  String get checkoutEtaUnknown => 'shown once your address is set';

  @override
  String checkoutTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get checkoutContinue => 'Continue Shopping';

  @override
  String get homeFreeDelivery => 'Free Delivery';

  @override
  String homeFreeDeliveryAbove(String amount) {
    return 'on orders above $amount';
  }

  @override
  String get homeEtaDeliveryIn => 'Delivery in';

  @override
  String get homeEtaDeliveryTime => 'Delivery time';

  @override
  String get homeEtaSetAddress => 'Set your address';

  @override
  String get homeEtaDelivery => 'Delivery';

  @override
  String get homeEtaFromLocal => 'From local stores';

  @override
  String homeEtaNearestStore(String store) {
    return 'Nearest store: $store';
  }

  @override
  String get homeEtaOutOfRange => 'Outside delivery area';

  @override
  String get homeAddressHint => 'Tap to set your delivery address';

  @override
  String get homeSearchProducts => 'Search for products';

  @override
  String homeSearchFor(String names) {
    return 'Search for $names…';
  }

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeShopNow => 'Shop now';

  @override
  String homeProductsFound(int count) {
    return '$count products found';
  }

  @override
  String get homeLoadFailed => 'Couldn\'t load products';

  @override
  String get homeNoProducts => 'No products found';

  @override
  String get homeLoadFailedBody =>
      'Check your internet connection and try again.';

  @override
  String get homeNoProductsBody => 'Try another category or search.';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeDealsHeading => 'Deals worth grabbing';

  @override
  String get homeBuyAgain => 'Buy again';

  @override
  String get homeBuyAgainSub => 'From your past orders';

  @override
  String get homeBestsellersHeading => 'Bestsellers';

  @override
  String homeMoreCount(int count) {
    return '+$count more';
  }

  @override
  String get homeSeeAllProducts => 'See all products';

  @override
  String get homeBrandsTitle => 'Shop by Brand';

  @override
  String get homeBrandsSubtitle => 'Your favourite brands, all in one place.';

  @override
  String get homeLocalBrandsTitle => 'Local Brands';

  @override
  String get homeLocalBrandsSubtitle =>
      'Shop direct from businesses in your area.';

  @override
  String homeProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get homeStoreFallback => 'Store';

  @override
  String get homeOpen => 'Open';

  @override
  String get homeClosed => 'Closed';

  @override
  String get addressAdded => 'Address added';

  @override
  String get addressUpdated => 'Address updated';

  @override
  String get addressDefaultFailed => 'Couldn\'t change the default address.';

  @override
  String get addressDeleteTitle => 'Delete address?';

  @override
  String get addressCancel => 'Cancel';

  @override
  String get addressDelete => 'Delete';

  @override
  String get addressDeleteFailed => 'Couldn\'t delete that address.';

  @override
  String get addressTitle => 'Delivery Addresses';

  @override
  String get addressEmptyTitle => 'No addresses yet';

  @override
  String get addressEmptyBody =>
      'Add a delivery address — type it, use your live location, or pick it on the map.';

  @override
  String get addressAdd => 'Add Address';

  @override
  String get addressAddNew => 'Add New Address';

  @override
  String get addressDefaultBadge => 'DEFAULT';

  @override
  String get addressEdit => 'Edit';

  @override
  String get addressSetDefault => 'Set as default';

  @override
  String get addressLabelHome => 'Home';

  @override
  String get addressLabelWork => 'Work';

  @override
  String get addressLabelOther => 'Other';

  @override
  String get addressLabelCurrent => 'Current location';

  @override
  String get addressFormAddTitle => 'Add Address';

  @override
  String get addressFormEditTitle => 'Edit Address';

  @override
  String get addressLocateFailed =>
      'Got your location, but couldn\'t find the address. Please type it in.';

  @override
  String get addressSettings => 'Settings';

  @override
  String get addressPickTitle => 'Delivery Location';

  @override
  String get addressPickHint => 'Search area, street or pincode';

  @override
  String get addressConfirmLocation => 'Confirm location';

  @override
  String get addressDeliverHere => 'Deliver here';

  @override
  String get addressSaveFailed =>
      'Couldn\'t save the address. Please try again.';

  @override
  String get addressChangeFailed => 'Couldn\'t change the address.';

  @override
  String get addressUseCurrent => 'Use current location';

  @override
  String get addressChooseMap => 'Choose on map';

  @override
  String get addressFindWhere => 'Find where you are right now';

  @override
  String get addressDragPin => 'Search or drag the pin';

  @override
  String get addressAddManually => 'Add address manually';

  @override
  String get addressTypeFull => 'Type your full address';

  @override
  String get addressSavedHeading => 'Saved addresses';

  @override
  String get addressCurrentHeading => 'Current delivery address';

  @override
  String get addressChooseTitle => 'Choose delivery address';

  @override
  String addressCurrentFallback(String coords) {
    return 'Current location ($coords)';
  }

  @override
  String addressPinnedFallback(String coords) {
    return 'Pinned location ($coords)';
  }

  @override
  String addressDeliveringTo(String address) {
    return 'Delivering to $address';
  }

  @override
  String addressMapSet(String coords) {
    return 'Map location set  •  $coords';
  }

  @override
  String get addressSaveAs => 'Save as';

  @override
  String get addressFullLabel => 'Full address';

  @override
  String get addressFullHint =>
      'House / flat no., building, street, area, city, pincode';

  @override
  String get addressFullError => 'Enter your full address';

  @override
  String get addressSaveChanges => 'Save changes';

  @override
  String get addressSaveAddress => 'Save address';

  @override
  String get kycTitle => 'KYC Documents';

  @override
  String get kycLoadFailed => 'Couldn\'t load your documents';

  @override
  String get kycUploadFailed => 'Could not upload this document.';

  @override
  String get kycStatusPending => 'PENDING';

  @override
  String get kycStatusVerified => 'VERIFIED';

  @override
  String get kycStatusRejected => 'REJECTED';

  @override
  String get kycUpload => 'Upload';

  @override
  String get kycReplace => 'Replace';

  @override
  String get kycDocPan => 'PAN Card';

  @override
  String get kycDocGst => 'GST Certificate';

  @override
  String get kycDocFssai => 'FSSAI License';

  @override
  String get kycDocBankProof => 'Bank Proof';

  @override
  String get kycDocAddressProof => 'Address Proof';

  @override
  String get storeNoProducts => 'This store has no products yet';

  @override
  String get storeStatusOpen => 'Open';

  @override
  String get storeStatusClosed => 'Closed';

  @override
  String get searchCameraFailed => 'Couldn\'t open the camera or gallery.';

  @override
  String get searchScannerFailed =>
      'Couldn\'t read this photo — the scanner needs a one-time download, so check your internet connection and try again.';

  @override
  String get searchNoMatch =>
      'Couldn\'t match this photo to a product. Try a clearer picture, or type the name.';

  @override
  String get searchReading => 'Reading your photo…';

  @override
  String get searchHint => 'Search products, brands, stores…';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchByVoiceOrPhoto => 'Search by voice or photo';

  @override
  String searchResultsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results found',
      one: '1 result found',
    );
    return '$_temp0';
  }

  @override
  String get searchIdleTitle => 'Search for products, brands or stores';

  @override
  String get searchTrySearching => 'Try searching for';

  @override
  String searchNoResultsTitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchNoResultsBody => 'Check the spelling or try something else.';

  @override
  String get searchDidYouMean => 'Did you mean:';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClearRecent => 'Clear';

  @override
  String get editCancel => 'Cancel';

  @override
  String get editSave => 'Save';

  @override
  String get editUploading => 'Uploading the picture…';

  @override
  String get editUploadFailed => 'Couldn\'t upload the picture. Try again.';

  @override
  String get editSaveFailed =>
      'Couldn\'t save that. Check your connection and try again.';

  @override
  String get editSaveFailedShort => 'Couldn\'t save that.';

  @override
  String get editSaveRetry => 'Couldn\'t save that. Try again.';

  @override
  String get editMoved => 'Moved.';

  @override
  String get editAlreadyFirst => 'Already the first.';

  @override
  String get editAlreadyLast => 'Already the last.';

  @override
  String get editReplaceCard => 'Replace this card';

  @override
  String get editReplaceCardHint => 'The card becomes the photo you pick';

  @override
  String get editCardReplaced => 'Card replaced.';

  @override
  String get editBackToNormalCard => 'Back to the normal card';

  @override
  String get editBackToNormalCardHint => 'Drops the photo card';

  @override
  String get editBackToNormalCardDone => 'Back to the normal card.';

  @override
  String get editChangePicture => 'Change picture';

  @override
  String get editChangePictureHint => 'Only the photo inside the card';

  @override
  String get editPickPhotoHint => 'Pick a photo from your gallery';

  @override
  String get editPictureChanged => 'Picture changed.';

  @override
  String get editShowPictureAgain => 'Show the picture again';

  @override
  String get editShowPictureAgainHint => 'Back to the product\'s photo';

  @override
  String get editPictureIsBack => 'Picture is back.';

  @override
  String get editUseProductPhoto => 'Use a product photo again';

  @override
  String get editUseProductPhotoHint => 'Drops the picture you set';

  @override
  String get editBackToProductPhoto => 'Back to the product photo.';

  @override
  String get editRemovePicture => 'Remove picture';

  @override
  String get editRemovePictureHint => 'The card shows no photo, only its text';

  @override
  String get editPictureRemoved => 'Picture removed.';

  @override
  String get editChangeName => 'Change name';

  @override
  String get editNameTitle => 'Name';

  @override
  String get editNameNote =>
      'A chip\'s page look follows its name, so renaming chips like Electronics or Kids changes how their page looks.';

  @override
  String get editNameChanged => 'Name changed.';

  @override
  String get editHideFromStore => 'Hide from store';

  @override
  String get editShowInStore => 'Show in store';

  @override
  String get editHidden => 'Hidden.';

  @override
  String get editShown => 'Shown.';

  @override
  String get editAddSubCategory => 'Add a sub-category';

  @override
  String get editAddSubCategoryHint => 'A new card inside this chip';

  @override
  String get editNewSubCategory => 'New sub-category';

  @override
  String get editAdded => 'Added.';

  @override
  String get editMoveEarlier => 'Move earlier';

  @override
  String get editMoveUp => 'Move up';

  @override
  String get editMoveLater => 'Move later';

  @override
  String get editMoveDown => 'Move down';

  @override
  String get editDelete => 'Delete';

  @override
  String get editRemoveSubsFirst => 'Remove its sub-categories first.';

  @override
  String editProductsAreIn(String name) {
    return 'Products are in \"$name\". Move them, or just hide it.';
  }

  @override
  String editDeleteNamed(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get editCannotUndo => 'This cannot be undone.';

  @override
  String get editDeleted => 'Deleted.';

  @override
  String get editEditPhotosDetails => 'Edit photos & details';

  @override
  String get editEditPhotosDetailsHint => 'The same screen the seller uses';

  @override
  String get editOpenProductPage => 'Open product page';

  @override
  String get editKeepVisibleHint => 'The seller keeps it and can show it again';

  @override
  String editHideNamed(String name) {
    return 'Hide \"$name\"?';
  }

  @override
  String get editHideNamedBody => 'Customers will no longer see it.';

  @override
  String get editHide => 'Hide';

  @override
  String get editHideFailed => 'Couldn\'t hide this product.';

  @override
  String get editNothingJustPicture => 'Nothing — just a picture';

  @override
  String get editWhereOpen => 'Where should it open?';

  @override
  String get editChangeText => 'Change text';

  @override
  String get editChangeTextHint => 'Heading, the line under it and the button';

  @override
  String get editHeadingTitle => 'Heading';

  @override
  String get editSubtitleTitle => 'Line under the heading';

  @override
  String get editButtonTextTitle => 'Button text';

  @override
  String get editTextChanged => 'Text changed.';

  @override
  String get editChangeWhereOpens => 'Change where it opens';

  @override
  String get editSaved => 'Saved.';

  @override
  String get editAddNewBanner => 'Add a new banner';

  @override
  String get editAddNewBannerHint => 'Opens all banners';

  @override
  String get editHideThisBanner => 'Hide this banner';

  @override
  String get editDeleteThisBanner => 'Delete this banner';

  @override
  String get editDeleteThisBannerQ => 'Delete this banner?';

  @override
  String get editBannerTitle => 'Banner';

  @override
  String get editEditNameDates => 'Edit name, dates & colours';

  @override
  String get editSwitchFestivalOff => 'Switch this festival off';

  @override
  String get editSwitchFestivalOffHint =>
      'Home goes back to the plain Festival chip';

  @override
  String get editOff => 'Off.';

  @override
  String get editAllFestivals => 'All festivals';

  @override
  String get editAllFestivalsHint => 'Add a new one, or change dates';

  @override
  String get editChangeBanner => 'Change banner';

  @override
  String editChangeBannerHint(String chip) {
    return 'The picture across the top of the $chip page';
  }

  @override
  String get editBannerChanged => 'Banner changed.';

  @override
  String get editRemoveTheBanner => 'Remove the banner';

  @override
  String get editRemoveTheBannerHint => 'Back to the title and artwork';

  @override
  String get editBannerRemoved => 'Banner removed.';

  @override
  String editSheetTitle(String title) {
    return 'Edit · $title';
  }

  @override
  String get editNothingToEdit => 'Nothing to edit here.';

  @override
  String get editModeOn => 'Editing — tap to finish';

  @override
  String get editModeOff => 'Edit mode';

  @override
  String get chipShopByCategory => 'Shop by category';

  @override
  String get chipTopDeals => 'Top Deals';

  @override
  String get chipTopBuys => 'Top buys';

  @override
  String get chipTopPicks => 'Top picks';

  @override
  String get chipFeatured => 'Featured';

  @override
  String chipUpToOff(int percent) {
    return 'Up to $percent% OFF';
  }

  @override
  String get chipHeroPharmacyKicker => 'HEALTH & WELLNESS';

  @override
  String get chipHeroPharmacyTitle => 'Pharmacy essentials';

  @override
  String get chipHeroKidsKicker => 'TINY TOTS';

  @override
  String get chipHeroKidsTitle => 'ZONE';

  @override
  String get chipHeroDecorKicker => 'REIMAGINE';

  @override
  String get chipHeroDecorTitle => 'your space';

  @override
  String get chipHeroImportedKicker => 'IMPORTED STORE';

  @override
  String get chipHeroImportedTitle => 'Global favourites';

  @override
  String get chipHeroImportedSubtitle =>
      'Discover brands from across the world';

  @override
  String get trackingTitle => 'Track Order';

  @override
  String get trackingNotFound => 'Tracking Not Found';

  @override
  String get trackingOrderMissing => 'Order not found.';

  @override
  String trackingOrderNumber(String id) {
    return 'Order $id';
  }

  @override
  String trackingExpected(String eta) {
    return 'Expected delivery: $eta';
  }

  @override
  String get trackingSummary => 'Order Summary';

  @override
  String get trackingTotal => 'Total';

  @override
  String get trackingPlaced => 'Placed';

  @override
  String get trackingPreparing => 'Preparing';

  @override
  String get trackingOnWay => 'On Way';

  @override
  String get trackingDelivered => 'Delivered';

  @override
  String get trackingInProgress => 'In progress';

  @override
  String get trackingWaitingLocation =>
      'Waiting for the delivery partner\'s location…';

  @override
  String get trackingRiderOnWay => 'is on the way with your order';

  @override
  String get trackingRiderFallback => 'Your delivery partner';

  @override
  String get trackingCallRider => 'Call';

  @override
  String get trackingCallFailed => 'Couldn\'t open the dialler.';

  @override
  String get trackingLiveNow => 'Live · just now';

  @override
  String trackingLiveSeconds(int seconds) {
    return 'Live · ${seconds}s ago';
  }

  @override
  String trackingLiveMinutes(int minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String get chipHeroBeautyShelfTitle => 'Elevate Your Everyday Glow';

  @override
  String get chipHeroBeautyShelfSubtitle => 'Top beauty picks curated for you';

  @override
  String get chipGiftingTitle => 'Perfect Gifts for Everyone';

  @override
  String get trackingPending => 'Pending';

  @override
  String get trackingEtaUnset => 'shown once your address is set';

  @override
  String get listingSortBy => 'Sort by';

  @override
  String get listingSort => 'Sort';

  @override
  String get listingRelevance => 'Relevance';

  @override
  String get listingPriceLow => 'Price: Low to High';

  @override
  String get listingPriceHigh => 'Price: High to Low';

  @override
  String get listingRating => 'Rating';

  @override
  String get listingDiscount => 'Discount';

  @override
  String get listingOffers => 'Offers';

  @override
  String get listingInStock => 'In stock';

  @override
  String get listingSetAddress => 'Set your delivery address';

  @override
  String listingDeliveringTo(String address) {
    return 'Delivering to: $address';
  }

  @override
  String get listingViewCart => 'View cart';

  @override
  String get listingNoProducts => 'No products here yet';

  @override
  String get listingNoMatches => 'No matches';

  @override
  String get listingTryClearingFilters => 'Try turning off a filter.';

  @override
  String get listingCheckBackSoon => 'Check back soon, or pick something else.';

  @override
  String get voiceClose => 'Close';

  @override
  String get voiceTipTomatoes => 'Say \"Fresh tomatoes…\"';

  @override
  String get voiceTipPhoto => 'Upload a photo of a pack';

  @override
  String get voiceTipMilkEggs => 'Say \"Amul milk and eggs…\"';

  @override
  String get voiceTipBiscuits => 'Say \"Biscuits and chips…\"';

  @override
  String get voiceStopped => 'Voice search stopped. Please try again.';

  @override
  String get voiceMicSettings =>
      'Allow the microphone for this app in Settings to search by voice.';

  @override
  String get voiceDidNotCatch => 'Didn\'t catch that. Tap Speak and try again.';

  @override
  String get voiceTitle => 'Search by voice\nor photo';

  @override
  String get voiceShoppingList => 'Your shopping list';

  @override
  String get voiceClearAll => 'Clear all';

  @override
  String get voiceNoMatch => 'No matching product yet';

  @override
  String get voiceShowProducts => 'Show products';

  @override
  String get voiceCamera => 'Camera';

  @override
  String get voiceGallery => 'Gallery';

  @override
  String get voiceUpload => 'Upload';

  @override
  String get voiceSpeak => 'Speak';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get festivalKickerFallback => 'CELEBRATE';

  @override
  String get festivalTitleFallback => 'Festive Store';

  @override
  String get festivalCardMittiKeGanpati => 'Mitti ke Ganpati';

  @override
  String get festivalCardGanpatiDarshan => 'Ganpati darshan';

  @override
  String get festivalCardSthapana => 'Sthapana';

  @override
  String get festivalPicks => 'Festive picks';

  @override
  String festivalChipPicks(String chip) {
    return '$chip picks';
  }

  @override
  String get festivalEverything => 'Everything for the celebration';

  @override
  String get festivalGettingReady => 'Festive store is getting ready';

  @override
  String festivalSpecialsOnWay(String name) {
    return '$name specials are on their way';
  }

  @override
  String get festivalEmptyBody =>
      'Sellers are adding festive products. Check back soon.';

  @override
  String get festivalSeeAllPooja => 'See all pooja essentials';

  @override
  String get festivalTileModak => 'Modak Essentials';

  @override
  String get festivalTileBhog => 'Bhog Essentials';

  @override
  String get festivalTileStaples => 'Cooking Staples';

  @override
  String get festivalTileCookware => 'Cookware Picks';

  @override
  String get festivalBhogKicker => 'PREPARE TRADITIONAL';

  @override
  String get festivalBhogTitle => 'Bhog & Festive Feasts';

  @override
  String get festivalBhogSubtitle => 'Everything for the bhog and the feast';

  @override
  String get authSkip => 'Skip';

  @override
  String get authHeading => 'Log In or Sign Up';

  @override
  String get authHeadingSub => 'Enter your email or mobile number';

  @override
  String get authForgot => 'Forgot password?';

  @override
  String authAgree(String app) {
    return 'By continuing, you agree to $app\'\n';
  }

  @override
  String get authTerms => 'Terms of Service';

  @override
  String get authAnd => ' and ';

  @override
  String get authPrivacy => 'Privacy Policy';

  @override
  String get authEmailHint => 'Email address';

  @override
  String get authIdHint => 'Enter email or phone number';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authNoLoginEmail => 'No login found with this email. New here?';

  @override
  String get authNoLoginPhone => 'No account on this number. New here?';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authContinue => 'Continue';

  @override
  String get authOrDivider => 'or';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authEnterValidEmail => 'Enter a valid email address.';

  @override
  String get authForgotTitle => 'Forgot Password';

  @override
  String get authForgotQuestion => 'Forgot Password?';

  @override
  String get authForgotBody => 'Enter your email to reset your password';

  @override
  String get authEmail => 'Email';

  @override
  String get authSendReset => 'Send Reset Link';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authInbox => 'Check your inbox';

  @override
  String authResetSent(String email) {
    return 'We have sent a password reset link to\n$email';
  }

  @override
  String get authResetTitle => 'Set New Password';

  @override
  String get authResetBody => 'Choose a new password for your account';

  @override
  String get authResetNewPassword => 'New password';

  @override
  String get authResetConfirmPassword => 'Confirm new password';

  @override
  String get authResetSubmit => 'Update Password';

  @override
  String get authResetDone => 'Password updated';

  @override
  String get authResetContinue => 'Continue';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authPasswordsDontMatch => 'Passwords don\'t match.';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authCreateBody =>
      'Enter a few details to set up your account and start shopping.';

  @override
  String get authUserName => 'User Name';

  @override
  String get authPhone => 'Phone number';

  @override
  String get authEmailAddress => 'Email Address';

  @override
  String get authNewPassword => 'Password (6+ characters)';

  @override
  String get authFriendsCode => 'Friends Code (optional)';

  @override
  String get authSubmit => 'Submit Securely';

  @override
  String get authRoleNote =>
      'You start as a customer. You can switch to Seller or Delivery Partner from your Profile later.';

  @override
  String get sellerDashTitle => 'Seller Dashboard';

  @override
  String get sellerDashNavHome => 'Home';

  @override
  String get sellerDashNavProducts => 'Products';

  @override
  String get sellerDashNavOrders => 'Orders';

  @override
  String get sellerDashNavMore => 'Profile';

  @override
  String get sellerDashLoading => 'Getting your store ready…';

  @override
  String get sellerDashLoadFailed => 'Couldn\'t load your store';

  @override
  String sellerDashHi(String name) {
    return 'Hi, $name';
  }

  @override
  String get sellerDashSub => 'Here\'s how your store is doing.';

  @override
  String get sellerDashStatProducts => 'Products';

  @override
  String get sellerDashStatOrders => 'Orders';

  @override
  String get sellerDashNoReviews => 'No reviews yet';

  @override
  String sellerDashReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get sellerDashQuickActions => 'Quick Actions';

  @override
  String get sellerDashAddProduct => 'Add Product';

  @override
  String get sellerDashStore => 'Store';

  @override
  String get sellerDashMyProducts => 'My Products';

  @override
  String get sellerDashViewAll => 'View All';

  @override
  String get sellerDashNoProducts => 'No products yet';

  @override
  String get sellerDashNoProductsBody =>
      'Add your first product and it will show up in the shop straight away.';

  @override
  String get sellerDashRecentOrders => 'Recent Orders';

  @override
  String get sellerDashNoOrdersBody =>
      'No orders yet. New ones land here the moment a customer checks out.';

  @override
  String sellerDashOrderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get sellerProductsUpdateFailed => 'Couldn\'t update this product.';

  @override
  String get sellerProductsDeleteTitle => 'Delete this product?';

  @override
  String sellerProductsDeleteBody(String name) {
    return '\"$name\" will be permanently removed. This cannot be undone.';
  }

  @override
  String get sellerProductsCancel => 'Cancel';

  @override
  String get sellerProductsDelete => 'Delete';

  @override
  String get sellerProductsDeleteFailed =>
      'Couldn\'t delete this product — it may already be part of past orders.';

  @override
  String get sellerProductsBgFailed =>
      'Couldn\'t remove the background — saving the original photo.';

  @override
  String get sellerProductsPhotoFailed => 'Couldn\'t update this photo.';

  @override
  String sellerProductsBoostDraft(String name) {
    return 'Check out $name!';
  }

  @override
  String get sellerProductsBoostTitle => 'Boost This Product';

  @override
  String get sellerProductsBoostHeadline => 'Headline';

  @override
  String get sellerProductsBoostDuration => 'Duration:';

  @override
  String sellerProductsBoostDays(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 ($price)';
  }

  @override
  String get sellerProductsBoostRequest => 'Request';

  @override
  String get sellerProductsBoostSent =>
      'Boost request submitted for admin approval.';

  @override
  String get sellerProductsBoostFailed => 'Couldn\'t submit boost request.';

  @override
  String get sellerProductsTitle => 'My Products';

  @override
  String get sellerProductsLoading => 'Loading your products…';

  @override
  String get sellerProductsLoadFailed => 'Couldn\'t load your products';

  @override
  String get sellerProductsSearchHint => 'Search your products';

  @override
  String get sellerProductsFilterAll => 'All';

  @override
  String get sellerProductsFilterActive => 'Active';

  @override
  String get sellerProductsFilterHidden => 'Hidden';

  @override
  String get sellerProductsFilterLowStock => 'Low Stock';

  @override
  String get sellerProductsEmptyTitle => 'No products yet';

  @override
  String get sellerProductsNoMatches => 'No matches';

  @override
  String get sellerProductsEmptyBody =>
      'Tap + to add your first product — it shows up in the shop straight away.';

  @override
  String get sellerProductsNoMatchesBody =>
      'Try turning the search or a filter off.';

  @override
  String get sellerProductsOutOfStock => 'Out of stock';

  @override
  String sellerProductsLowStock(int count) {
    return 'Low: $count left';
  }

  @override
  String sellerProductsInStock(int count) {
    return 'Stock: $count';
  }

  @override
  String get sellerProductsEdit => 'Edit';

  @override
  String get sellerProductsBoost => 'Boost';

  @override
  String get sellerProductsHide => 'Hide';

  @override
  String get sellerProductsUnhide => 'Unhide';

  @override
  String get deliveryAccept => 'Accept';

  @override
  String get deliveryDelivered => 'Delivered';

  @override
  String get deliveryViewAll => 'View All';

  @override
  String get deliveryNoAddress => 'No address';

  @override
  String get deliveryDashNavHome => 'Home';

  @override
  String get deliveryDashNavDeliveries => 'Deliveries';

  @override
  String get deliveryDashNavMore => 'Profile';

  @override
  String get deliveryDashLoading => 'Getting your runs ready…';

  @override
  String get deliveryDashLoadFailed => 'Couldn\'t load your runs';

  @override
  String get deliveryDashOnlineToggleFailed =>
      'Couldn\'t update your online status. Check your connection and try again.';

  @override
  String get deliveryDashNoReviews => 'No reviews';

  @override
  String deliveryDashReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String deliveryDashYouEarn(String amount) {
    return 'You earn $amount';
  }

  @override
  String get deliveryDashOfflineNote =>
      'You\'re offline. Go online to take new orders.';

  @override
  String get deliveryDashMyDeliveries => 'My Deliveries';

  @override
  String get deliveryDashNoActiveBody =>
      'No active deliveries. Pick one up from the list below.';

  @override
  String get deliveryDashAvailableOrders => 'Available Orders';

  @override
  String get deliveryDashNoneWaitingBody =>
      'No orders waiting for pickup right now. Pull down to check again.';

  @override
  String get deliveryDashClaimFailed =>
      'Couldn\'t take this delivery — someone may have taken it first.';

  @override
  String get deliveryDashMarkDeliveredFailed =>
      'Couldn\'t mark it delivered. Check your connection and try again.';

  @override
  String get deliveryOrdersTitle => 'My Delivery';

  @override
  String get deliveryOrdersLoading => 'Loading the runs…';

  @override
  String get deliveryOrdersLoadFailed => 'Couldn\'t load the runs';

  @override
  String get deliveryOrdersClaimLost =>
      'This order was just taken by another partner.';

  @override
  String get deliveryOrdersAcceptFailed =>
      'Couldn\'t accept this order. Check your connection and try again.';

  @override
  String get deliveryOrdersMarkDeliveredFailed =>
      'Couldn\'t mark this order delivered. Check your connection and try again.';

  @override
  String get deliveryOrdersFeeNotRecorded =>
      'Marked delivered, but the delivery fee could not be recorded — tell the admin.';

  @override
  String get deliveryOrdersPickFrom => 'PICK FROM';

  @override
  String get deliveryOrdersDeliverTo => 'DELIVER TO';

  @override
  String get deliveryOrdersStoreFallback => 'The seller\'s store';

  @override
  String deliveryOrdersNote(String note) {
    return 'Note: $note';
  }

  @override
  String get deliveryOrdersCall => 'Call';

  @override
  String get deliveryOrdersCallFailed => 'Couldn\'t open the dialler.';

  @override
  String get deliveryOrdersNavigate => 'Navigate';

  @override
  String get deliveryOrdersNavigateToStore => 'Pickup point';

  @override
  String get deliveryOrdersNavigateToCustomer => 'Customer';

  @override
  String get deliveryOrdersNavigateFailed =>
      'This location has no map coordinates yet.';

  @override
  String get deliveryNavigateTitle => 'Directions';

  @override
  String get deliveryNavigateLocating => 'Finding your location…';

  @override
  String deliveryNavigateDistance(String distance) {
    return '$distance away';
  }

  @override
  String deliveryNavigateByRoad(String distance, int minutes) {
    return '$distance · $minutes min by road';
  }

  @override
  String get deliveryNavigateNoRoute =>
      'Road route unavailable — showing a straight line';

  @override
  String get deliveryNavigateOpenMaps => 'Google Maps';

  @override
  String get deliveryNavigateMapsFailed => 'Couldn\'t open Google Maps.';

  @override
  String get deliveryNavigateRetry => 'Retry';

  @override
  String get deliveryNavigateRecenter => 'Re-centre';

  @override
  String get deliveryEarningsTitle => 'My Earnings';

  @override
  String get deliveryEarningsLoading => 'Adding up your earnings…';

  @override
  String get deliveryEarningsLoadFailed => 'Couldn\'t load your earnings';

  @override
  String get deliveryEarningsTotal => 'Total Earnings';

  @override
  String get deliveryEarningsPayouts => 'Payouts & withdrawals';

  @override
  String get deliveryEarningsEmpty => 'No deliveries completed yet';

  @override
  String get deliveryEarningsFeeFallback => 'Delivery fee';

  @override
  String get deliveryMoreTitle => 'Profile';

  @override
  String get deliveryMoreLogout => 'Log Out';

  @override
  String get adminUsersTitle => 'Manage Users';

  @override
  String get adminUsersLoading => 'Loading users…';

  @override
  String get adminUsersLoadFailed => 'Couldn\'t load users';

  @override
  String get adminUsersEmptyTitle => 'No accounts yet';

  @override
  String get adminUsersEmptyBody =>
      'Everyone who signs up lands here, ready to be managed.';

  @override
  String get adminUsersDeleteTitle => 'Delete this account?';

  @override
  String adminUsersDeleteBody(String name) {
    return 'This permanently deletes $name and everything tied to their account (orders, products, addresses). This cannot be undone.';
  }

  @override
  String get adminUsersCancel => 'Cancel';

  @override
  String get adminUsersDelete => 'Delete';

  @override
  String get adminUsersDeleted => 'Account deleted';

  @override
  String get adminUsersErrSelf => 'You can\'t delete your own account.';

  @override
  String get adminUsersErrReferred =>
      'This account referred others and cannot be deleted yet.';

  @override
  String get adminUsersErrNotAdmin => 'Only admins can delete accounts.';

  @override
  String get adminUsersErrGeneric => 'Could not delete this account.';

  @override
  String get adminModerationTitle => 'Moderation';

  @override
  String get adminModerationLoading => 'Loading the queue…';

  @override
  String get adminModerationLoadFailed => 'Couldn\'t load the queue';

  @override
  String get adminModerationReturns => 'Return Requests';

  @override
  String get adminModerationReturnsSub => 'Approve or reject customer returns';

  @override
  String get adminModerationIssues => 'Order Issues';

  @override
  String get adminModerationIssuesSub => 'Resolve reported problems';

  @override
  String get adminModerationSlots => 'Sponsored Slots';

  @override
  String get adminModerationSlotsSub => 'Approve seller boost requests';

  @override
  String get adminModerationPayouts => 'Payouts';

  @override
  String get adminModerationPayoutsSub =>
      'What sellers and delivery partners are owed';

  @override
  String get adminIssuesTitle => 'Order Issues';

  @override
  String get adminIssuesLoading => 'Loading the issues…';

  @override
  String get adminIssuesLoadFailed => 'Couldn\'t load the issues';

  @override
  String get adminIssuesEmptyTitle => 'Nothing reported';

  @override
  String get adminIssuesEmptyBody =>
      'Customer issues land here as soon as they are raised.';

  @override
  String adminIssuesOrder(String id) {
    return 'Order: $id';
  }

  @override
  String get adminIssuesResolveTitle => 'Resolve Issue';

  @override
  String get adminIssuesRefundLabel => 'Refund Amount (₹, 0 if none)';

  @override
  String get adminIssuesCancel => 'Cancel';

  @override
  String get adminIssuesResolve => 'Resolve';

  @override
  String get adminIssuesReject => 'Reject';

  @override
  String get adminIssuesUpdateFailed => 'Couldn\'t update this issue.';

  @override
  String get adminReturnsTitle => 'Return Requests';

  @override
  String get adminReturnsLoading => 'Loading the requests…';

  @override
  String get adminReturnsLoadFailed => 'Couldn\'t load the requests';

  @override
  String get adminReturnsEmptyTitle => 'No return requests';

  @override
  String get adminReturnsEmptyBody =>
      'Returns waiting on you will show up here.';

  @override
  String adminReturnsOrder(String id) {
    return 'Order: $id';
  }

  @override
  String get adminReturnsApproveTitle => 'Approve Return';

  @override
  String get adminReturnsRefundLabel => 'Refund Amount (₹)';

  @override
  String get adminReturnsCancel => 'Cancel';

  @override
  String get adminReturnsApprove => 'Approve';

  @override
  String get adminReturnsReject => 'Reject';

  @override
  String get adminReturnsUpdateFailed =>
      'Couldn\'t update this request — the order may be outside its return window.';

  @override
  String get adminSlotsTitle => 'Sponsored Slots';

  @override
  String get adminSlotsLoading => 'Loading the slots…';

  @override
  String get adminSlotsLoadFailed => 'Couldn\'t load the slots';

  @override
  String get adminSlotsEmptyTitle => 'No sponsored slots';

  @override
  String get adminSlotsEmptyBody =>
      'Slots you create show up here, with who has taken them.';

  @override
  String get adminSlotsUnknownProduct => 'Unknown product';

  @override
  String adminSlotsProduct(String name) {
    return 'Product: $name';
  }

  @override
  String adminSlotsDaysFee(int days, String fee) {
    return '$days days · $fee';
  }

  @override
  String get adminSlotsApprove => 'Approve';

  @override
  String get adminSlotsReject => 'Reject';

  @override
  String get adminSlotsRejectTitle => 'Reject Request';

  @override
  String get adminSlotsReasonLabel => 'Reason (optional)';

  @override
  String get adminSlotsCancel => 'Cancel';

  @override
  String get adminSlotsUpdateFailed => 'Couldn\'t update this request.';

  @override
  String get adminDashTitle => 'Admin Dashboard';

  @override
  String get adminDashNavHome => 'Home';

  @override
  String get adminDashNavUsers => 'Users';

  @override
  String get adminDashNavModeration => 'Moderation';

  @override
  String get adminDashLoading => 'Counting the shop…';

  @override
  String get adminDashLoadFailed => 'Couldn\'t load the numbers';

  @override
  String get adminDashStatProducts => 'Products';

  @override
  String get adminDashStatOrders => 'Orders';

  @override
  String get adminDashStatSellers => 'Sellers';

  @override
  String get adminDashStatDelivery => 'Delivery Partners';

  @override
  String get adminDashEditorTitle => 'View & edit your store';

  @override
  String get adminDashEditorBody =>
      'Opens the app just as customers see it. Switch on Edit mode and tap the pencil on a banner, chip or festival to change it right there.';

  @override
  String get adminDashCategories => 'Categories';

  @override
  String get adminDashCategoriesSub =>
      'Add, rename or hide the chips customers browse';

  @override
  String get adminDashRecentOrders => 'Recent Orders';

  @override
  String get adminDashNoOrders => 'No orders yet — the shop is quiet.';

  @override
  String adminDashOrderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get adminPayoutsTitle => 'Payout Requests';

  @override
  String get adminPayoutsLoading => 'Loading the payout queue…';

  @override
  String get adminPayoutsLoadFailed => 'Couldn\'t load the payout queue';

  @override
  String get adminPayoutsEmpty => 'No payouts waiting on a decision.';

  @override
  String adminPayoutsWaiting(int count) {
    return 'Waiting on you ($count)';
  }

  @override
  String get adminPayoutsDecided => 'Decided';

  @override
  String adminPayoutsSendTo(String method) {
    return 'Send to $method';
  }

  @override
  String adminPayoutsPartnerNote(String note) {
    return 'Partner says: $note';
  }

  @override
  String get adminPayoutsApprove => 'Approve';

  @override
  String get adminPayoutsReject => 'Reject';

  @override
  String get adminPayoutsRejectTitle => 'Reject this payout?';

  @override
  String get adminPayoutsReasonLabel => 'Reason (the partner will read this)';

  @override
  String get adminPayoutsCancel => 'Cancel';

  @override
  String get adminPayoutsUpdateFailed =>
      'Couldn\'t update this request. Try again.';

  @override
  String get adminPayoutsMarkPaid => 'Mark as paid';

  @override
  String get adminPayoutsMarkPaidButton => 'Mark paid';

  @override
  String get adminPayoutsReferenceLabel => 'Bank / UPI reference (optional)';

  @override
  String get adminPayoutsReferenceHelper =>
      'So the transfer can be traced later';

  @override
  String get adminPayoutsMarkPaidFailed => 'Couldn\'t mark it paid. Try again.';

  @override
  String adminPayoutsReference(String ref) {
    return 'Reference $ref';
  }

  @override
  String get adminBannersTitle => 'Banners';

  @override
  String get adminBannersFab => 'Banner';

  @override
  String get adminBannersLoading => 'Loading banners…';

  @override
  String get adminBannersLoadFailed => 'Couldn\'t load banners';

  @override
  String get adminBannersHint =>
      'These slide across the top of Home, in this order. Switch a banner off to hide it without deleting it.';

  @override
  String get adminBannersEmpty => 'No banners yet.';

  @override
  String get adminBannersNew => 'New banner';

  @override
  String get adminBannersShapeHint =>
      'Shown at 851 × 396. Other shapes are cropped to fit.';

  @override
  String get adminBannersLinkLabel => 'When tapped, open';

  @override
  String get adminBannersLinkNothing => 'Nothing';

  @override
  String get adminBannersUpload => 'Upload banner';

  @override
  String get adminBannersAdded => 'Banner added.';

  @override
  String get adminBannersUploadFailed =>
      'Couldn\'t upload the banner. Try again.';

  @override
  String get adminBannersUpdateFailed => 'Couldn\'t update it.';

  @override
  String get adminBannersReorderFailed => 'Couldn\'t reorder.';

  @override
  String get adminBannersDeleteTitle => 'Delete this banner?';

  @override
  String get adminBannersDeleteBody => 'This cannot be undone.';

  @override
  String get adminBannersCancel => 'Cancel';

  @override
  String get adminBannersDelete => 'Delete';

  @override
  String get adminBannersDeleteFailed => 'Couldn\'t delete it.';

  @override
  String get adminBannersOpensNothing => 'Opens nothing';

  @override
  String adminBannersOpens(String target) {
    return 'Opens $target';
  }

  @override
  String get adminBannersMoveUp => 'Move up';

  @override
  String get adminBannersMoveDown => 'Move down';

  @override
  String get adminCategoriesTitle => 'Categories';

  @override
  String get adminCategoriesFab => 'Main category';

  @override
  String get adminCategoriesLoading => 'Loading categories…';

  @override
  String get adminCategoriesLoadFailed => 'Couldn\'t load categories';

  @override
  String get adminCategoriesHint =>
      'Sub-categories become the cards, tiles and shelves on a store page. Home\'s chips (Electronics, Beauty, …) are fixed in the app, so a new main category shows up on the Categories tab, not as a Home chip.';

  @override
  String get adminCategoriesNewSub => 'New sub-category';

  @override
  String get adminCategoriesNewMain => 'New main category';

  @override
  String get adminCategoriesEditSub => 'Edit sub-category';

  @override
  String get adminCategoriesEditMain => 'Edit main category';

  @override
  String get adminCategoriesNameLabel => 'Name';

  @override
  String get adminCategoriesOrderLabel => 'Order (smaller comes first)';

  @override
  String get adminCategoriesShowInApp => 'Show in the app';

  @override
  String get adminCategoriesErrName => 'Enter a name';

  @override
  String get adminCategoriesErrClash => 'This name is already used';

  @override
  String get adminCategoriesSave => 'Save';

  @override
  String get adminCategoriesSaved => 'Saved.';

  @override
  String get adminCategoriesSaveFailed =>
      'Couldn\'t save. Check your connection and try again.';

  @override
  String get adminCategoriesRemoveSubsFirst =>
      'Remove its sub-categories first.';

  @override
  String adminCategoriesHasProducts(int count, String name) {
    return '$count products are in \"$name\". Move them to another category first, or just switch it off.';
  }

  @override
  String adminCategoriesDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get adminCategoriesDeleteBody => 'This cannot be undone.';

  @override
  String get adminCategoriesCancel => 'Cancel';

  @override
  String get adminCategoriesDelete => 'Delete';

  @override
  String get adminCategoriesDeleted => 'Deleted.';

  @override
  String get adminCategoriesDeleteFailed => 'Couldn\'t delete it.';

  @override
  String get adminCategoriesUpdateFailed => 'Couldn\'t update it.';

  @override
  String adminCategoriesMainSubtitle(int subs, int products) {
    String _temp0 = intl.Intl.pluralLogic(
      subs,
      locale: localeName,
      other: '$subs sub-categories',
      one: '1 sub-category',
    );
    String _temp1 = intl.Intl.pluralLogic(
      products,
      locale: localeName,
      other: '$products products',
      one: '1 product',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get adminCategoriesHidden => ' · hidden';

  @override
  String adminCategoriesProductsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String get adminCategoriesAddSub => 'Sub-category';

  @override
  String get adminCategoriesEdit => 'Edit';

  @override
  String get adminFestivalsTitle => 'Festival calendar';

  @override
  String get adminFestivalsFab => 'Festival';

  @override
  String get adminFestivalsLoading => 'Loading the calendar…';

  @override
  String get adminFestivalsLoadFailed => 'Couldn\'t load the calendar';

  @override
  String get adminFestivalsNoneLive =>
      'No festival is on today, so Home shows the plain \"Festival\" chip.';

  @override
  String adminFestivalsOnToday(String title, String chip) {
    return 'On today: $title. Home\'s chip reads \"$chip\".';
  }

  @override
  String get adminFestivalsNew => 'New festival';

  @override
  String get adminFestivalsEditDialog => 'Edit festival';

  @override
  String get adminFestivalsEdit => 'Edit';

  @override
  String get adminFestivalsChipLabel => 'Chip name (short, e.g. Diwali)';

  @override
  String get adminFestivalsKickerLabel => 'Small line (e.g. CELEBRATE)';

  @override
  String get adminFestivalsTitleLabel => 'Big title (e.g. Ganesh Chaturthi)';

  @override
  String adminFestivalsFrom(String date) {
    return 'From $date';
  }

  @override
  String adminFestivalsTo(String date) {
    return 'To $date';
  }

  @override
  String get adminFestivalsColours => 'Colours';

  @override
  String get adminFestivalsPresetSaffron => 'Saffron';

  @override
  String get adminFestivalsPresetRose => 'Rose';

  @override
  String get adminFestivalsPresetGold => 'Gold';

  @override
  String get adminFestivalsPresetGreen => 'Green';

  @override
  String get adminFestivalsPresetIndigo => 'Indigo';

  @override
  String get adminFestivalsPresetCoral => 'Coral';

  @override
  String get adminFestivalsHeader => 'Header';

  @override
  String get adminFestivalsFade => 'Fade';

  @override
  String get adminFestivalsAccent => 'Accent';

  @override
  String get adminFestivalsShowPooja => 'Show pooja artwork';

  @override
  String get adminFestivalsShowPoojaSub =>
      'Pooja thali and the Bhog & Festive Feasts section';

  @override
  String get adminFestivalsActive => 'Active';

  @override
  String get adminFestivalsErrChipTitle => 'Enter the chip name and title';

  @override
  String get adminFestivalsErrColours => 'Colours must look like #FFD9A8';

  @override
  String get adminFestivalsSave => 'Save';

  @override
  String get adminFestivalsSaved => 'Saved.';

  @override
  String get adminFestivalsSaveFailed =>
      'Couldn\'t save. Check your connection and try again.';

  @override
  String adminFestivalsDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get adminFestivalsDeleteBody => 'This cannot be undone.';

  @override
  String get adminFestivalsCancel => 'Cancel';

  @override
  String get adminFestivalsDelete => 'Delete';

  @override
  String get adminFestivalsDeleteFailed => 'Couldn\'t delete it.';

  @override
  String get adminFestivalsLive => 'LIVE';

  @override
  String get adminFestivalsPoojaSuffix => ' · pooja';

  @override
  String get adminFestivalsOffSuffix => ' · off';

  @override
  String get sellerReviewsTitle => 'Reviews';

  @override
  String get sellerReviewsLoading => 'Loading your reviews…';

  @override
  String get sellerReviewsLoadFailed => 'Couldn\'t load your reviews';

  @override
  String get sellerReviewsEmptyTitle => 'No reviews yet';

  @override
  String get sellerReviewsEmptyBody =>
      'Reviews buyers leave on your products show up here.';

  @override
  String get sellerReviewsProductFallback => 'Product';

  @override
  String get sellerBoostsTitle => 'My Boost Requests';

  @override
  String get sellerBoostsLoading => 'Loading your requests…';

  @override
  String get sellerBoostsLoadFailed => 'Couldn\'t load your requests';

  @override
  String get sellerBoostsEmptyTitle => 'No boost requests';

  @override
  String get sellerBoostsEmptyBody =>
      'Requests you send for a boost show up here with their status.';

  @override
  String get sellerBoostsProductFallback => 'Product';

  @override
  String sellerBoostsProduct(String name) {
    return 'Product: $name';
  }

  @override
  String sellerBoostsDaysFee(int days, String fee) {
    return '$days days · $fee';
  }

  @override
  String sellerBoostsReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get sellerEarningsTitle => 'Earnings';

  @override
  String get sellerEarningsLoading => 'Adding up your earnings…';

  @override
  String get sellerEarningsLoadFailed => 'Couldn\'t load your earnings';

  @override
  String get sellerEarningsNetPayout => 'Net Payout';

  @override
  String get sellerEarningsTotalSales => 'Total Sales';

  @override
  String get sellerEarningsCommissionPaid => 'Commission Paid';

  @override
  String get sellerEarningsPayouts => 'Payouts & withdrawals';

  @override
  String sellerEarningsDeliveredOrders(int count) {
    return 'Delivered Orders ($count)';
  }

  @override
  String get sellerEarningsEmpty => 'No delivered orders yet.';

  @override
  String sellerEarningsOrderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get sellerMoreTitle => 'Profile';

  @override
  String get sellerMoreSectionBusiness => 'Business';

  @override
  String get sellerMoreStore => 'Store Profile';

  @override
  String get sellerMoreStoreSub => 'Banner, logo, address, delivery radius';

  @override
  String get sellerMoreBusiness => 'Business Details';

  @override
  String get sellerMoreBusinessSub => 'PAN, GST, bank account, UPI';

  @override
  String get sellerMoreKyc => 'KYC Documents';

  @override
  String get sellerMoreKycSub => 'Upload verification documents';

  @override
  String get sellerMoreSectionPerformance => 'Performance';

  @override
  String get sellerMoreEarnings => 'Earnings';

  @override
  String get sellerMoreEarningsSub => 'Payouts and commission breakdown';

  @override
  String get sellerMoreReviews => 'Reviews';

  @override
  String get sellerMoreReviewsSub => 'What customers are saying';

  @override
  String get sellerMoreBoosts => 'My Boost Requests';

  @override
  String get sellerMoreBoostsSub => 'Sponsored product slot status';

  @override
  String get sellerMoreLogout => 'Log Out';

  @override
  String get sellerBusinessTitle => 'Business Details';

  @override
  String get sellerBusinessLoading => 'Loading your details…';

  @override
  String get sellerBusinessLoadFailed => 'Couldn\'t load your details';

  @override
  String get sellerBusinessErrName => 'Business name is required.';

  @override
  String get sellerBusinessSaved => 'Business details saved.';

  @override
  String get sellerBusinessSaveFailed => 'Couldn\'t save your details.';

  @override
  String get sellerBusinessNameLabel => 'Business Name';

  @override
  String get sellerBusinessOwnerLabel => 'Owner Name';

  @override
  String get sellerBusinessAddressLabel => 'Business Address';

  @override
  String get sellerBusinessCompliance => 'Compliance';

  @override
  String get sellerBusinessPanLabel => 'PAN Number';

  @override
  String get sellerBusinessGstLabel => 'GST Number (optional)';

  @override
  String get sellerBusinessFssaiLabel => 'FSSAI Number (optional)';

  @override
  String get sellerBusinessPayoutDetails => 'Payout Details';

  @override
  String get sellerBusinessBankLabel => 'Bank Account Number';

  @override
  String get sellerBusinessIfscLabel => 'IFSC Code';

  @override
  String get sellerBusinessUpiLabel => 'UPI ID (optional)';

  @override
  String get sellerBusinessSave => 'Save Details';

  @override
  String get sellerBusinessNext => 'Next';

  @override
  String get sellerBusinessBack => 'Back';

  @override
  String sellerBusinessStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get sellerProductDetailProductFallback => 'Product';

  @override
  String get sellerProductDetailHidden => 'Hidden';

  @override
  String get sellerProductDetailOutOfStock => 'Out of stock';

  @override
  String sellerProductDetailStock(int count) {
    return 'Stock: $count';
  }

  @override
  String get sellerProductDetailDescription => 'Description';

  @override
  String get sellerProductDetailNoDescription => 'No description added.';

  @override
  String get sellerProductDetailHighlights => 'Highlights';

  @override
  String sellerProductDetailReviews(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get sellerProductDetailReviewsFailed => 'Couldn\'t load the reviews.';

  @override
  String get sellerProductDetailTryAgain => 'Try again';

  @override
  String get sellerProductDetailNoReviews => 'No reviews yet for this product.';

  @override
  String get sellerProductDetailLive => 'Live in shop';

  @override
  String sellerProductDetailLowStock(int count) {
    return 'Only $count left';
  }

  @override
  String sellerProductDetailDiscountValue(int percent) {
    return '$percent% off';
  }

  @override
  String get sellerProductDetailPerformance => 'Performance';

  @override
  String get sellerProductDetailSold => 'Units sold';

  @override
  String get sellerProductDetailRevenue => 'Revenue';

  @override
  String get sellerProductDetailRating => 'Rating';

  @override
  String get sellerProductDetailNoRating => 'None yet';

  @override
  String get sellerProductDetailSalesFailed => 'Couldn\'t load the sales.';

  @override
  String get sellerProductDetailDetails => 'Details';

  @override
  String get sellerProductDetailCategory => 'Category';

  @override
  String get sellerProductDetailUnit => 'Pack size';

  @override
  String get sellerProductDetailBrand => 'Brand';

  @override
  String get sellerProductDetailMrp => 'MRP';

  @override
  String get sellerProductDetailNotSet => 'Not set';

  @override
  String get sellerProductDetailAddDescriptionHint =>
      'Customers buy more when they can read about a product. Write a few lines, or let AI draft them.';

  @override
  String get sellerProductDetailAddDescription => 'Add description';

  @override
  String get sellerProductDetailEdit => 'Edit product';

  @override
  String get sellerProductDetailHide => 'Hide from shop';

  @override
  String get sellerProductDetailUnhide => 'Show in shop';

  @override
  String get sellerProductDetailHiddenDone => 'Hidden from the shop.';

  @override
  String get sellerProductDetailShownDone => 'Back in the shop.';

  @override
  String get sellerProductDetailUpdateFailed =>
      'Couldn\'t update this product.';

  @override
  String get sellerOrdersTitle => 'Manage Orders';

  @override
  String get sellerOrdersLoading => 'Loading your orders…';

  @override
  String get sellerOrdersLoadFailed => 'Couldn\'t load your orders';

  @override
  String get sellerOrdersEmptyTitle => 'No orders yet';

  @override
  String get sellerOrdersEmptyBody =>
      'Orders from your customers land here the moment they check out.';

  @override
  String get sellerOrdersChipActive => 'Active';

  @override
  String get sellerOrdersChipAll => 'All';

  @override
  String sellerOrdersOrderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get sellerOrdersItemFallback => 'Item';

  @override
  String get sellerOrdersConfirm => 'Confirm Order';

  @override
  String get sellerOrdersPreparing => 'Start Preparing';

  @override
  String get sellerOrdersReady => 'Mark Ready for Pickup';

  @override
  String get sellerOrdersUpdateFailed => 'Couldn\'t update this order.';

  @override
  String get sellerOrdersCancelTitle => 'Cancel this order?';

  @override
  String get sellerOrdersCancelBody =>
      'The customer will be notified and any wallet amount used will be refunded automatically.';

  @override
  String get sellerOrdersNo => 'No';

  @override
  String get sellerOrdersCancel => 'Cancel';

  @override
  String get sellerOrdersCancelConfirm => 'Cancel Order';

  @override
  String get sellerLocationGpsOff => 'Turn on location (GPS) on your phone.';

  @override
  String get sellerLocationPermissionBlocked =>
      'Location permission is blocked. Allow it in app settings.';

  @override
  String get sellerLocationSettings => 'Settings';

  @override
  String get sellerLocationPermissionNeeded =>
      'Location permission is needed to use GPS.';

  @override
  String get sellerLocationFailed =>
      'Couldn\'t get your location. Try again outdoors.';

  @override
  String get sellerLocationNotFound =>
      'Couldn\'t find that address. Add the city or pincode, or move the map.';

  @override
  String get sellerLocationHint =>
      'Use GPS, search an address, or move the map to place the pin.';

  @override
  String get sellerLocationResolving => 'Finding address…';

  @override
  String get sellerLocationLookupUnavailable =>
      'Pin placed. Address lookup unavailable — you can type it in.';

  @override
  String get sellerStoreTitle => 'Store Profile';

  @override
  String get sellerStoreLoading => 'Loading your store…';

  @override
  String get sellerStoreLoadFailed => 'Couldn\'t load your store';

  @override
  String get sellerStoreBannerLabel => 'Store Banner';

  @override
  String get sellerStoreLogoLabel => 'Store Logo';

  @override
  String sellerStoreAddPhoto(String what) {
    return 'Add $what';
  }

  @override
  String get sellerStoreApproved => 'Approved';

  @override
  String get sellerStorePendingApproval => 'Pending Approval';

  @override
  String get sellerStoreNameLabel => 'Store Name';

  @override
  String get sellerStoreDescriptionLabel => 'Description';

  @override
  String get sellerStoreAddressLabel => 'Address';

  @override
  String get sellerStoreCityLabel => 'City';

  @override
  String get sellerStorePincodeLabel => 'Pincode';

  @override
  String get sellerStoreRadiusLabel => 'Delivery Radius (km)';

  @override
  String get sellerStoreOpen => 'Store Open';

  @override
  String get sellerStoreSave => 'Save Store Profile';

  @override
  String get sellerStoreNext => 'Next';

  @override
  String get sellerStoreBack => 'Back';

  @override
  String sellerStoreStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get sellerStoreStepFinish => 'Open & save';

  @override
  String sellerStorePinSet(String lat, String lng) {
    return 'Store pin set  •  $lat, $lng';
  }

  @override
  String get sellerStorePinNotSet => 'Store location not set';

  @override
  String get sellerStorePinHelp =>
      'Customers and delivery partners use this pin to find you. Use live location, search your address, or drag the map.';

  @override
  String get sellerStoreChangeLocation => 'Change location on map';

  @override
  String get sellerStoreSetLocation => 'Set location on map';

  @override
  String get sellerStoreErrName => 'Store name is required.';

  @override
  String get sellerStoreSaved => 'Store profile saved.';

  @override
  String get sellerStoreSaveFailed => 'Couldn\'t save your store profile.';

  @override
  String get sellerStoreUpdateAddressTitle => 'Update address?';

  @override
  String sellerStoreUpdateAddressBody(String address) {
    return 'The pin is at:\n\n$address\n\nReplace the address, city and pincode with this?';
  }

  @override
  String get sellerStoreKeepMine => 'Keep mine';

  @override
  String get sellerStoreUseThis => 'Use this';

  @override
  String get sellerStorePickTitle => 'Store Location';

  @override
  String get sellerStorePickHint => 'Search store address, area or pincode';

  @override
  String get sellerStorePickConfirm => 'Confirm store location';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get addProductEditTitle => 'Edit Product';

  @override
  String get addProductCategoriesFailed => 'Couldn\'t load the category list.';

  @override
  String get addProductTryAgain => 'Try again';

  @override
  String get addProductCategoryLabel => 'Category';

  @override
  String get addProductCategoryChoose => 'Choose a category';

  @override
  String get categoryPickerTitle => 'Choose a category';

  @override
  String get categoryPickerSearchHint => 'Search, e.g. toys, candles, coffee';

  @override
  String get categoryPickerClear => 'Clear';

  @override
  String get categoryPickerBack => 'Back to all categories';

  @override
  String categoryPickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String categoryPickerNoMatch(String query) {
    return 'No category matches \"$query\".';
  }

  @override
  String addProductPhotosSkipped(int max) {
    return 'Up to $max photos — extra ones skipped.';
  }

  @override
  String get addProductBgSomeFailed =>
      'Couldn\'t remove the background from some photos — the originals will be used.';

  @override
  String get addProductErrName => 'Enter a product name first';

  @override
  String get addProductGenerateFailed => 'Could not generate description';

  @override
  String get addProductErrRequired => 'Enter a name, category, and price';

  @override
  String get addProductWaitBg => 'Please wait — removing the background…';

  @override
  String get addProductSaveFailed =>
      'Could not save this product. Please try again.';

  @override
  String get addProductTapToAdd => 'Tap to add product photos';

  @override
  String addProductUpTo(int max) {
    return 'Up to $max';
  }

  @override
  String get addProductAddMore => 'Add more';

  @override
  String addProductPhotosHelp(int count, int max) {
    return '$count/$max photos · the first one is the main photo — tap another to make it main';
  }

  @override
  String get addProductMainBadge => 'MAIN';

  @override
  String get addProductRemoveBg => 'Remove background';

  @override
  String get addProductRemoveBgOn => 'New photos are cut out automatically';

  @override
  String get addProductRemoveBgOff => 'Photo will be saved as it is';

  @override
  String get addProductNameLabel => 'Product name';

  @override
  String get addProductBrandLabel => 'Brand';

  @override
  String addProductMyStore(String name) {
    return 'My store: $name';
  }

  @override
  String get addProductCompanyBrand => 'Company brand';

  @override
  String addProductMyStoreNote(String name) {
    return 'Customers will see this under your business brand \"$name\".';
  }

  @override
  String get addProductCompanyBrandOptional => 'Company brand (optional)';

  @override
  String get addProductBrandHint => 'e.g. Apple, Samsung, Amul';

  @override
  String get addProductBrandHelper =>
      'Set up your store profile to sell under your own business name.';

  @override
  String get addProductPriceLabel => 'Selling price';

  @override
  String get addProductMrpLabel => 'MRP (optional)';

  @override
  String get addProductUnitLabel => 'Unit (e.g. 1 kg)';

  @override
  String get addProductStockLabel => 'Stock';

  @override
  String get addProductDescriptionLabel => 'Description';

  @override
  String get addProductGenerate => 'Generate with AI';

  @override
  String get addProductDescriptionHint =>
      'What is this product? What makes it worth buying?';

  @override
  String get addProductHighlights => 'Highlights';

  @override
  String get addProductGenerating => 'Writing…';

  @override
  String get addProductExtend => 'Add more with AI';

  @override
  String addProductDescriptionRule(int min, int max) {
    return 'The AI writes $min–$max words: what it is, why it is worth buying, what is in the pack, how to use it, and what buyers ask.';
  }

  @override
  String addProductWordCount(int count, int min, int max) {
    return '$count words · target $min–$max';
  }

  @override
  String get addProductWritingHelp =>
      'Writing a full page — about a minute for 700 to 1500 words.';

  @override
  String addProductGenerateShort(int count) {
    return 'Only $count words so far — tap Generate again to extend the page.';
  }

  @override
  String get addProductGenerateFromNotes =>
      'Written from your own notes — the AI did not write this, because the server has no AI key set.';

  @override
  String get addProductGenerateOffline =>
      'No internet — the AI writer needs a connection.';

  @override
  String get addProductGenerateSlow =>
      'The AI writer took too long this time. Tap Generate again.';

  @override
  String get addProductGenerateSignIn => 'Sign in again to use the AI writer.';

  @override
  String get addProductGenerateMissing =>
      'The AI writer is not deployed on this project yet — see supabase/README.md.';

  @override
  String get addProductGenerateRateLimited =>
      'Too many descriptions at once, right now. Wait a minute and try again.';

  @override
  String get addProductGenerateBusy =>
      'The AI writer on the server failed. Try again in a minute.';

  @override
  String get addProductGenerateGarbled =>
      'The AI writer answered with something unreadable. Try again in a minute.';

  @override
  String get addProductGenerateEmpty =>
      'The AI writer came back with nothing. Tap Generate again.';

  @override
  String get addProductGenerateMisconfigured =>
      'The AI writer\'s key or address on the server is wrong.';

  @override
  String get addProductGenerateCrashed =>
      'The AI writer broke on the server. Its log says why.';

  @override
  String get addProductGenerateAiRefused =>
      'Written from your own notes — the AI key was refused.';

  @override
  String get addProductGenerateAiAddress =>
      'Written from your own notes — the AI address is wrong.';

  @override
  String get addProductGenerateAiDown =>
      'Written from your own notes — the AI service was slow or down. Tap Generate again.';

  @override
  String get addProductUpdate => 'Update Product';

  @override
  String get addProductSave => 'Save Product';

  @override
  String get sellerBusinessErrRequired => 'This is needed.';

  @override
  String get sellerBusinessErrPan =>
      'A PAN is 10 characters: 5 letters, 4 digits, 1 letter (ABCDE1234F).';

  @override
  String get sellerBusinessErrGst =>
      'A GSTIN is 15 characters, like 22ABCDE1234F1Z5.';

  @override
  String get sellerBusinessErrFssai => 'An FSSAI licence number is 14 digits.';

  @override
  String get sellerBusinessErrBank =>
      'An account number is 9 to 18 digits, with no spaces or commas.';

  @override
  String get sellerBusinessErrIfsc =>
      'An IFSC is 11 characters, like SBIN0001234 (the 5th is a zero).';

  @override
  String get sellerBusinessErrUpi => 'A UPI ID looks like name@bank.';

  @override
  String get sellerBusinessErrIfscNeeded =>
      'Add the IFSC of this account, or payouts cannot reach it.';

  @override
  String get sellerBusinessErrBankNeeded =>
      'Add the account number this IFSC belongs to.';

  @override
  String get sellerBusinessFixErrors =>
      'Some details need fixing — see the red notes below.';

  @override
  String get sellerBusinessApprovedTitle => 'Approved — you can sell';

  @override
  String get sellerBusinessApprovedBody =>
      'Your business is verified. Changing these details may send it back for review.';

  @override
  String get sellerBusinessRejectedTitle => 'Not approved yet';

  @override
  String get sellerBusinessRejectedBody =>
      'Some details could not be verified. Correct them and save to be reviewed again.';

  @override
  String get sellerBusinessPendingTitle => 'Under review';

  @override
  String get sellerBusinessPendingBody =>
      'We are checking your details. This usually takes 1–2 working days.';

  @override
  String get sellerBusinessSectionBusiness => 'Business';

  @override
  String get sellerBusinessSectionBusinessBody =>
      'The name and address on your invoices.';

  @override
  String get sellerBusinessComplianceBody =>
      'Needed to verify your business. GST and FSSAI only if you have them.';

  @override
  String get sellerBusinessFssaiHint => '14-digit number';

  @override
  String get sellerBusinessFssaiHelper => 'Needed if you sell food.';

  @override
  String get sellerBusinessPayoutBody => 'Where your earnings are sent.';

  @override
  String get sellerBusinessBankHint => 'Digits only';

  @override
  String get sellerBusinessIfscHelper =>
      'Printed on your cheque book or passbook.';

  @override
  String get kycHintPan => 'A clear photo of the front of your PAN card.';

  @override
  String get kycHintGst =>
      'Your GST registration certificate, if you have one.';

  @override
  String get kycHintFssai => 'Your FSSAI licence, if you sell food.';

  @override
  String get kycHintBank =>
      'A cancelled cheque or the first page of your passbook.';

  @override
  String get kycHintAddress => 'Aadhaar, electricity bill or rent agreement.';

  @override
  String get kycTakePhoto => 'Take a photo';

  @override
  String get kycFromGallery => 'Choose from gallery';

  @override
  String get kycAllVerified => 'All documents verified';

  @override
  String kycProgress(int verified, int total) {
    return '$verified of $total required documents verified';
  }

  @override
  String get kycAllVerifiedBody => 'Nothing more to do here.';

  @override
  String kycUploadRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Upload $count more required documents to be reviewed.',
      one: 'Upload 1 more required document to be reviewed.',
    );
    return '$_temp0';
  }

  @override
  String get kycUnderReviewBody =>
      'Everything is uploaded. We will verify it within 1–2 working days.';

  @override
  String get kycStatusUnderReview => 'Under review';

  @override
  String get kycRequired => 'Required';

  @override
  String get kycOptional => 'Optional';

  @override
  String get kycNotUploaded => 'Not uploaded';

  @override
  String get kycRejectedHelp =>
      'This could not be verified. Upload a clearer copy.';

  @override
  String get sellerEarningsAllTime => 'All time';

  @override
  String get sellerEarningsThisMonth => 'This month';

  @override
  String get sellerEarningsLast7Days => 'Last 7 days';

  @override
  String sellerEarningsFromOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'From $count delivered orders',
      one: 'From 1 delivered order',
      zero: 'No delivered orders',
    );
    return '$_temp0';
  }

  @override
  String get sellerEarningsEmptyPeriod => 'No delivered orders in this period.';

  @override
  String get sellerEarningsHowItWorks =>
      'Money reaches this page when an order is delivered: the sale, less the platform\'s commission, is your payout.';

  @override
  String sellerEarningsBreakdown(String sales, String commission) {
    return 'Sale $sales · Commission $commission';
  }

  @override
  String get sellerOrdersJustNow => 'Just now';

  @override
  String sellerOrdersMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String sellerOrdersHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get sellerOrdersWaitingPickup =>
      'Packed and ready. A delivery partner will pick it up.';

  @override
  String get sellerOrdersOnTheWay => 'On its way to the customer.';

  @override
  String sellerOrdersItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String sellerOrdersMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more items',
      one: '+1 more item',
    );
    return '$_temp0';
  }

  @override
  String get sellerStoreErrPincode => 'A PIN code is 6 digits.';

  @override
  String get sellerStorePendingBody =>
      'Customers will see your store once it is approved.';

  @override
  String get sellerStoreSectionBranding => 'Branding';

  @override
  String get sellerStoreSectionBrandingBody =>
      'The first thing customers see. A wide banner and a square logo work best.';

  @override
  String get sellerStoreSectionAbout => 'About your store';

  @override
  String get sellerStoreSectionAboutBody =>
      'Your name and a line on what you sell.';

  @override
  String get sellerStoreDescriptionHint =>
      'e.g. Fresh fruit, vegetables and daily groceries, delivered the same day.';

  @override
  String get sellerStoreSectionAddress => 'Address';

  @override
  String get sellerStoreSectionAddressBody =>
      'Where your store is. Shown to customers and delivery partners.';

  @override
  String get sellerStoreSectionDelivery => 'Location & delivery';

  @override
  String get sellerStoreSectionDeliveryBody =>
      'Your pin on the map and how far you deliver.';

  @override
  String get sellerStoreRadiusHelper =>
      'Customers farther than this will not see your products.';

  @override
  String get sellerStoreOpenBody => 'Customers can order from you now.';

  @override
  String get sellerStoreClosedBody =>
      'Your store shows as closed and takes no orders.';

  @override
  String get sellerStoreMissingBanner => 'banner';

  @override
  String get sellerStoreMissingLogo => 'logo';

  @override
  String get sellerStoreMissingDescription => 'description';

  @override
  String get sellerStoreMissingAddress => 'full address';

  @override
  String get sellerStoreMissingPin => 'map pin';

  @override
  String sellerStoreComplete(int percent) {
    return 'Store profile $percent% complete';
  }

  @override
  String sellerStoreStillMissing(String items) {
    return 'Still to add: $items.';
  }

  @override
  String get checkoutChange => 'Change';

  @override
  String get checkoutPickAddress => 'Choose a delivery address';

  @override
  String get checkoutAddAddress => 'Add a new address';

  @override
  String get checkoutReceiverTitle => 'Who will receive the order?';

  @override
  String get checkoutSaveAndProceed => 'Save and proceed';

  @override
  String get checkoutPayTitle => 'Select payment method';

  @override
  String checkoutBillTotal(String amount) {
    return 'Bill total: $amount';
  }

  @override
  String get checkoutPayNow => 'Pay now';

  @override
  String get cartProceedToPay => 'Proceed To Pay';

  @override
  String get cartTotalLabel => 'TOTAL';

  @override
  String get cartSelectAddress => 'Select address to proceed';

  @override
  String cartDeliveringTo(String label) {
    return 'Delivering to $label';
  }

  @override
  String get cartToPay => 'To pay';

  @override
  String get cartCoupons => 'Apply coupon';

  @override
  String get cartCancellationTitle => 'Cancellation policy';

  @override
  String get cartCancellationBody =>
      'Orders cannot be cancelled once packed for delivery. In case of unexpected delays, a refund will be provided, if applicable.';

  @override
  String get variantSheetTitle => 'Choose Variant';

  @override
  String get variantSheetFailed => 'Could not load the sizes for this product.';

  @override
  String get variantSheetRetry => 'Try again';

  @override
  String get sellerDashBalance => 'Balance';

  @override
  String get sellerDashSoldOut => 'Sold out products';

  @override
  String get sellerDashLowStockTile => 'Low stock products';

  @override
  String get sellerDashWeekSales => 'Sales in the last 7 days';

  @override
  String sellerDashWeekTotal(String amount) {
    return '$amount this week';
  }

  @override
  String get sellerDashCategoryCount => 'Products by category';

  @override
  String get addProductVariantsTitle => 'Sizes (variants)';

  @override
  String get addProductVariantsHelp =>
      'Sell this product in more sizes, like 500 GM and 1 KG. Add each size buyers can choose, including the main one.';

  @override
  String get addProductVariantsFailed =>
      'Could not load this product\'s sizes. Open it again to edit them.';

  @override
  String get addProductVariantName => 'Size, e.g. 500 GM';

  @override
  String get addProductVariantAdd => 'Add a size';

  @override
  String get addProductVariantRemove => 'Remove this size';

  @override
  String get sellerOrdersSearchHint => 'Search order ID, item or address';

  @override
  String get sellerOrdersDates => 'Dates';

  @override
  String get sellerOrdersClearDates => 'Clear dates';

  @override
  String get sellerReturnsTitle => 'Returns';

  @override
  String get sellerReturnsLoading => 'Loading returns…';

  @override
  String get sellerReturnsLoadFailed => 'Couldn\'t load returns';

  @override
  String get sellerReturnsEmptyTitle => 'No return requests';

  @override
  String get sellerReturnsEmptyBody =>
      'When a customer asks to return an item from one of your orders, it shows up here.';

  @override
  String sellerReturnsOrder(String id) {
    return 'Order #$id';
  }

  @override
  String sellerReturnsRefund(String amount) {
    return 'Refund $amount';
  }

  @override
  String get sellerMoreReturns => 'Returns';

  @override
  String get sellerMoreReturnsSub => 'Return requests on your orders';

  @override
  String get sellerProductsStockTitle => 'Update stock';

  @override
  String get sellerProductsStockCancel => 'Cancel';

  @override
  String get sellerProductsStockSave => 'Save';

  @override
  String sellerProductsStockSaved(int count) {
    return 'Stock set to $count';
  }

  @override
  String get sellerProductsStockFailed =>
      'Couldn\'t update the stock. Try again.';

  @override
  String deliveryDashHi(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get deliveryDashOnlinePill => 'Online';

  @override
  String get deliveryDashOfflinePill => 'Offline';

  @override
  String get deliveryDashTodayPerformance => 'Today\'s Performance';

  @override
  String get deliveryDashTodayEarnings => 'Today\'s Earnings';

  @override
  String get deliveryDashOrdersDelivered => 'Orders Delivered';

  @override
  String get deliveryDashCashCollected => 'Cash Collected';

  @override
  String get deliveryDashTodayOrders => 'Today\'s Orders';

  @override
  String get deliveryDashOverview => 'Delivery Overview';

  @override
  String get deliveryDashActiveOrders => 'Active orders';

  @override
  String get deliveryDashAvailableBalance => 'Available Balance';

  @override
  String get deliveryDashCashInHand => 'Cash in Hand';

  @override
  String get deliveryDashTotalOrders => 'Total Orders';

  @override
  String get deliveryDashOutForDelivery => 'Out For Delivery';

  @override
  String get deliveryDashDeliveredLegend => 'Delivered';

  @override
  String get deliveryDashCancelledLegend => 'Cancelled';

  @override
  String get deliveryDashTotalEarnedShort => 'Total earned';

  @override
  String get deliveryDashNavEarnings => 'Earnings';

  @override
  String get deliveryDashEarningsChart => 'Earnings';

  @override
  String get deliveryDashLast7 => 'Last 7 days';

  @override
  String get deliveryDashLast30 => 'Last 30 days';

  @override
  String get deliveryDashPerformance => 'Delivery Performance';

  @override
  String get deliveryDashPerfTotal => 'Total';

  @override
  String get deliveryDashPerfActive => 'Active';

  @override
  String get deliveryDashSuccessRate => 'Delivery Success Rate';

  @override
  String get deliveryDashCancelRate => 'Cancellation Rate';

  @override
  String get deliveryDashInProgress => 'In Progress';

  @override
  String get deliveryOrdersChipAll => 'All';

  @override
  String get deliveryOrdersReadyForPickup => 'Ready for Pickup';

  @override
  String get deliveryOrdersSearchHint => 'Search order, item or address';

  @override
  String deliveryOrdersNumber(String id) {
    return '#$id';
  }

  @override
  String deliveryOrdersPackSize(String size) {
    return 'Pack Size: $size';
  }

  @override
  String deliveryOrdersMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more items',
      one: '+1 more item',
    );
    return '$_temp0';
  }

  @override
  String get deliveryOrdersPayCod => 'Pay via COD';

  @override
  String get deliveryOrdersPaidCod => 'Paid via COD';

  @override
  String get deliveryOrdersPaidOnline => 'Paid online';

  @override
  String get deliveryOrdersCollect => 'Collect from Customer';

  @override
  String get deliveryOrdersEmptyTitle => 'No orders here';

  @override
  String get deliveryOrdersEmptyBody =>
      'Orders ready for pickup, on the way and delivered show up here.';

  @override
  String get deliveryEarningsToday => 'Today\'s Earning';

  @override
  String get deliveryEarningsWallet => 'Wallet';

  @override
  String get deliveryEarningsWeek => 'This Week';

  @override
  String get deliveryEarningsSettled => 'Settlement History';

  @override
  String get deliveryEarningsHistory => 'Earnings history';

  @override
  String get deliveryCashTitle => 'Cash Collection';

  @override
  String get deliveryCashLoading => 'Loading cash collection…';

  @override
  String get deliveryCashLoadFailed => 'Couldn\'t load cash collection';

  @override
  String get deliveryCashToday => 'Collected today';

  @override
  String get deliveryCashTotal => 'Collected in all';

  @override
  String get deliveryCashEmptyTitle => 'No cash collected yet';

  @override
  String get deliveryCashEmptyBody =>
      'Cash-on-delivery orders you deliver show up here with the amount you collected.';

  @override
  String deliveryCashOrder(String id) {
    return 'Order #$id';
  }

  @override
  String get deliveryProfileEdit => 'Edit';

  @override
  String get deliveryProfileSupport => 'Help & Support';

  @override
  String get deliveryProfileChat => 'Chat with Support';

  @override
  String get deliveryProfilePolicies => 'Help & Policies';

  @override
  String get deliveryProfilePrivacy => 'Privacy Policy';

  @override
  String get deliveryProfileTerms => 'Terms & Conditions';

  @override
  String get deliveryProfileAccount => 'Account';

  @override
  String get deliveryProfileSettings => 'Settings';

  @override
  String get deliverySettingsGeneral => 'General';

  @override
  String get deliverySettingsNotifications => 'Notifications';

  @override
  String get deliverySettingsPassword => 'Change Password';

  @override
  String get deliverySettingsNewPassword => 'New password';

  @override
  String get deliverySettingsConfirmPassword => 'Confirm new password';

  @override
  String get deliverySettingsTooShort => 'At least 6 characters';

  @override
  String get deliverySettingsMismatch => 'The two passwords don\'t match';

  @override
  String get deliverySettingsPasswordSaved => 'Password changed';

  @override
  String get deliverySettingsCancel => 'Cancel';

  @override
  String get deliverySettingsSave => 'Save';

  @override
  String get deliverySettingsDelete => 'Delete Account';

  @override
  String get deliverySettingsDeleteBody =>
      'A delivery partner account has runs and payouts linked to it, so it is closed by our support team. Contact support and they will close it for you.';

  @override
  String get deliverySettingsContact => 'Contact support';

  @override
  String get deliveryEditTitle => 'Edit Profile';

  @override
  String get deliveryEditStepOne => 'Update your personal details';

  @override
  String get deliveryEditStepTwo => 'Your vehicle and documents';

  @override
  String get deliveryEditLoading => 'Loading your profile…';

  @override
  String get deliveryEditLoadFailed => 'Couldn\'t load your profile';

  @override
  String get deliveryEditName => 'Full Name';

  @override
  String get deliveryEditEmail => 'Email';

  @override
  String get deliveryEditBirth => 'Date of Birth';

  @override
  String get deliveryEditBirthHint => 'Select date';

  @override
  String get deliveryEditCity => 'City';

  @override
  String get deliveryEditMobile => 'Mobile Number';

  @override
  String get deliveryEditAddress => 'Address';

  @override
  String get deliveryEditVehicle => 'Vehicle';

  @override
  String get deliveryEditVehicleBike => 'Bike';

  @override
  String get deliveryEditVehicleScooter => 'Scooter';

  @override
  String get deliveryEditVehicleEv => 'EV Scooter';

  @override
  String get deliveryEditVehicleBicycle => 'Bicycle';

  @override
  String get deliveryEditVehicleNumber => 'Vehicle Number';

  @override
  String get deliveryEditLicence => 'Driving Licence Number';

  @override
  String get deliveryEditDocuments => 'National ID & Driving Licence';

  @override
  String get deliveryEditDocumentsBody =>
      'Upload or change your ID and licence photos';

  @override
  String get deliveryEditNext => 'Next';

  @override
  String get deliveryEditBack => 'Back';

  @override
  String get deliveryEditSaved => 'Profile saved';

  @override
  String get deliveryEditSaveFailed =>
      'Couldn\'t save your profile. Try again.';

  @override
  String get supportChatTitle => 'Chat with Support';

  @override
  String get supportChatLoading => 'Loading your chat…';

  @override
  String get supportChatLoadFailed => 'Couldn\'t load the chat';

  @override
  String get supportChatEmptyTitle => 'How can we help?';

  @override
  String get supportChatEmptyBody =>
      'Send us a message and our team will reply here.';

  @override
  String get supportChatHint => 'Type a message…';

  @override
  String get supportChatSendFailed => 'Couldn\'t send the message. Try again.';

  @override
  String get supportChatToday => 'Today';

  @override
  String get supportChatYesterday => 'Yesterday';

  @override
  String get adminSupportTitle => 'Support chats';

  @override
  String get adminSupportSub => 'Messages from customers, sellers and riders';

  @override
  String get adminSupportLoading => 'Loading support chats…';

  @override
  String get adminSupportLoadFailed => 'Couldn\'t load support chats';

  @override
  String get adminSupportEmptyTitle => 'No messages yet';

  @override
  String get adminSupportEmptyBody =>
      'When someone writes to support, their chat shows up here.';
}
