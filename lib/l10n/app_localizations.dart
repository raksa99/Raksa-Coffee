import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Translation values map compiled directly from ARB definitions
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      "appTitle": "Raksa Coffee POS",
      "counter": "Counter",
      "salesReport": "Sales Report",
      "currentOrder": "Current Order",
      "heldQueue": "Held Queue",
      "subtotal": "Subtotal",
      "discount": "Discount",
      "tax": "Tax",
      "total": "Total",
      "holdOrder": "Hold Order",
      "checkout": "Checkout",
      "paymentSuccessful": "Payment Successful",
      "printReceipt": "Print Receipt",
      "done": "Done",
      "changeDue": "Change Due",
      "addMenuItem": "Add Menu Item",
      "offlineCache": "Offline Cache",
      "selectPaymentMethod": "Select Payment Method",
      "invoiceSummary": "Invoice Summary",
      "cash": "Cash",
      "card": "Card Terminal",
      "qrScan": "QR Scan",
      "tendered": "Tendered",
      "reprint": "Re-print",
      "resetHistory": "Reset History",
      "reprintReceipt": "Reprint Receipt",
      "heldOrdersQueue": "Held Orders Queue",
      "noHeldOrders": "No held orders found",
      "resume": "Resume",
      
      // Dynamic category tabs
      "all": "All",
      "espresso": "Espresso",
      "brew": "Brew",
      "noncoffee": "Non-Coffee",
      "pastries": "Pastries",

      // Sidebar & Cart UI
      "emptyCart": "Your cart is empty",
      "addNotes": "Add Notes...",
      
      // Checkout Dialog Layout
      "waitingTerminal": "Waiting for Terminal...",
      "terminalInstructions": "Insert, swipe, or tap card on payment device.",
      "scanToPay": "Scan to Pay",
      "bakongGuide": "Scan with any Bakong or Mobile Banking App",
      "instantCredit": "Instantly credited to Raksa Coffee ABA merchant account.",
      "paymentMethod": "Payment Method",
      "paidVia": "PAID VIA",
      "amountTendered": "Amount Tendered",
      "scanViewEInvoice": "Scan to view e-invoice",
      
      // Daily Report Dashboard
      "grossSales": "Gross Sales",
      "ordersCount": "Orders",
      "avgTicket": "Avg Ticket",
      "topSelling": "Top Selling Products",
      "salesLedger": "Sales Ledger",
      "itemsPurchased": "Items Purchased",
      
      // Hold Dialog & Discounts
      "holdOrderTitle": "Hold Order",
      "enterHoldName": "Enter a name to identify this order:",
      "holdNamePlaceholder": "e.g. Table 5, John",
      "cancel": "Cancel",
      "hold": "Hold",
      "customDiscount": "Custom Discount",
      "apply": "Apply"
    },
    'km': {
      "appTitle": "កាហ្វេ រក្សា ភីអូអេស",
      "counter": "បញ្ជរលក់",
      "salesReport": "របាយការណ៍លក់",
      "currentOrder": "ការបញ្ជាទិញបច្ចុប្បន្ន",
      "heldQueue": "បញ្ជីរង់ចាំ",
      "subtotal": "សរុបរង",
      "discount": "ការបញ្ចុះតម្លៃ",
      "tax": "ពន្ធ (៨%)",
      "total": "សរុប",
      "holdOrder": "រក្សាទុកសិន",
      "checkout": "គិតលុយ",
      "paymentSuccessful": "ការទូទាត់ជោគជ័យ",
      "printReceipt": "បោះពុម្ពវិក្កយបត្រ",
      "done": "រួចរាល់",
      "changeDue": "លុយអាប់",
      "addMenuItem": "បន្ថែមមុខទំនិញ",
      "offlineCache": "ម៉ាស៊ីនក្រៅបណ្តាញ",
      "selectPaymentMethod": "ជ្រើសរើសវិធីទូទាត់",
      "invoiceSummary": "សេចក្តីសង្ខេបវិក្កយបត្រ",
      "cash": "សាច់ប្រាក់",
      "card": "ម៉ាស៊ីនកាត",
      "qrScan": "ស្កេន QR",
      "tendered": "ប្រាក់ទទួលបាន",
      "reprint": "បោះពុម្ពឡើងវិញ",
      "resetHistory": "សម្អាតប្រវត្តិ",
      "reprintReceipt": "បោះពុម្ពវិក្កយបត្រឡើងវិញ",
      "heldOrdersQueue": "បញ្ជីការបញ្ជាទិញដែលរក្សាទុក",
      "noHeldOrders": "មិនមានការរក្សាទុកទេ",
      "resume": "បន្តសកម្មភាព",
      
      // Dynamic category tabs
      "all": "ទាំងអស់",
      "espresso": "អេសប្រេសូ",
      "brew": "កាហ្វេតម្រង",
      "noncoffee": "ភេសជ្ជៈគ្មានកាហ្វេ",
      "pastries": "នំនិងនំបុ័ង",

      // Sidebar & Cart UI
      "emptyCart": "កន្ត្រកទំនិញរបស់អ្នកទទេ",
      "addNotes": "បន្ថែមចំណាំ...",
      
      // Checkout Dialog Layout
      "waitingTerminal": "កំពុងរង់ចាំម៉ាស៊ីនទូទាត់...",
      "terminalInstructions": "សូមស៊ក ស្កេន ឬប៉ះកាតនៅលើម៉ាស៊ីនទូទាត់",
      "scanToPay": "ស្កេនដើម្បីទូទាត់",
      "bakongGuide": "ស្កេនជាមួយកម្មវិធីបាគង ឬកម្មវិធីធនាគារផ្សេងៗ",
      "instantCredit": "ប្រាក់នឹងចូលគណនីអាជីវករ កាហ្វេ រក្សា ភ្លាមៗ",
      "paymentMethod": "វិធីសាស្ត្រទូទាត់",
      "paidVia": "បានទូទាត់តាម",
      "amountTendered": "ប្រាក់ទទួលបាន",
      "scanViewEInvoice": "ស្កេនដើម្បីមើលវិក្កយបត្រអេឡិចត្រូនិច",
      
      // Daily Report Dashboard
      "grossSales": "ការលក់សរុប",
      "ordersCount": "ការបញ្ជាទិញ",
      "avgTicket": "មធ្យមភាគវិក្កយបត្រ",
      "topSelling": "ផលិតផលលក់ដាច់បំផុត",
      "salesLedger": "បញ្ជីលក់ប្រចាំថ្ងៃ",
      "itemsPurchased": "ទំនិញដែលបានទិញ",
      
      // Hold Dialog & Discounts
      "holdOrderTitle": "រក្សាទុកការបញ្ជាទិញ",
      "enterHoldName": "សូមបញ្ចូលឈ្មោះដើម្បីសម្គាល់ការបញ្ជាទិញនេះ៖",
      "holdNamePlaceholder": "ឧទាហរណ៍៖ តុលេខ៥, យ៉ន",
      "cancel": "បោះបង់",
      "hold": "រក្សាទុក",
      "customDiscount": "ការបញ្ចុះតម្លៃពិសេស",
      "apply": "អនុវត្ត"
    }
  };

  String translate(String key) {
    final lang = locale.languageCode == 'km' ? 'km' : 'en';
    return _translations[lang]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'km'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension LocalizedString on String {
  String tr(BuildContext context) {
    return AppLocalizations.of(context)?.translate(this) ?? this;
  }
}
