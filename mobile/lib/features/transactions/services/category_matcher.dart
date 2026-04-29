// Offline keyword-based auto-categoriser.
//
// Matches raw bank statement descriptions against keyword rules and returns
// the best matching category ID from the provided category list.
//
// Rules are checked in order — first match wins. Each rule is a list of
// lowercase substrings; a rule matches if ANY substring is found in the
// normalised description. Income vs expense is disambiguated by [isIncome].

import '../models/category.dart';

class CategoryMatcher {
  CategoryMatcher(this._categories);

  final List<Category> _categories;

  // ── Rules ────────────────────────────────────────────────────────────────
  // Format: { categoryName: [keywords...] }
  // Ordered most-specific → least-specific within each group.
  // Income rules are checked only when isIncome=true; expense rules otherwise.

  static const _incomeRules = <String, List<String>>{
    'Salary': [
      'payroll', 'direct dep', 'salary', 'wages', 'adp ', 'paychex',
      'gusto', 'workday', 'type: payroll',
    ],
    'Freelance': ['freelance', 'contract pay', 'upwork', 'fiverr'],
    'Investment Income': [
      'dividend', 'interest earned', 'capital gain', 'schwab', 'fidelity dep',
      'vanguard dep',
    ],
    'Other Income': ['refund', 'reimbursement', 'cashback', 'cash back', 'reward'],
  };

  static const _expenseRules = <String, List<String>>{
    // ── Transfer / internal ───────────────────────────────────────────────
    'Transfer': [
      'transfer', 'zelle', 'venmo', 'paypal', 'cashapp', 'cash app',
      'from share', 'to share', 'loan payment', 'external transfer',
    ],

    // ── Debt ─────────────────────────────────────────────────────────────
    'Credit Card Payment': ['credit card pmt', 'cc payment', 'card payment'],
    'Student Loan': ['student loan', 'navient', 'sallie mae', 'mohela', 'nelnet'],

    // ── Housing ──────────────────────────────────────────────────────────
    'Rent / Mortgage': [
      'rent', 'mortgage', 'hoa', 'property mgmt', 'management co',
      'apartments', 'realty',
    ],
    'Utilities': [
      'electric', 'gas co', 'water dept', 'sewer', 'trash', 'waste mgmt',
      'evergy', 'kcpl', 'westar', 'xcel energy', 'pg&e', 'duke energy',
      'con ed', 'national grid',
    ],
    'Internet / Phone': [
      'at&t', 'verizon', 'tmobile', 't-mobile', 'sprint', 'comcast',
      'xfinity', 'spectrum', 'cox comm', 'centurylink', 'lumen',
      'google fi', 'mint mobile', 'cricket',
    ],
    'Home Maintenance': [
      'home depot', 'homedepot', 'lowes', "lowe's", 'ace hardware',
      'true value', 'menards', 'plumb', 'electric repair', 'roofing',
    ],
    'Home Insurance': ['home insurance', 'homeowner', 'renters insurance'],

    // ── Food & Dining ─────────────────────────────────────────────────────
    'Coffee & Drinks': [
      'starbucks', 'dutch bros', 'dunkin', 'caribou', 'biggby',
      'scooters coffee', "scooter's", 'panera', 'coffee',
    ],
    'Takeout & Delivery': [
      'doordash', 'uber eats', 'grubhub', 'instacart', 'postmates',
      'seamless', 'delivery',
    ],
    'Restaurants': [
      'mcdonald', "mcdonald's", 'burger king', "wendy's", 'wendys',
      'subway', 'chipotle', 'taco bell', "arby's", 'arbys', "culver's",
      'culvers', 'sonic', 'dairy queen', "dq ", "chick-fil-a", 'chickfila',
      "applebee's", 'applebees', 'chilis', "chili's", 'ihop',
      'olive garden', 'red lobster', 'outback', 'denny', "denny's",
      'waffle house', 'cracker barrel', 'panda express', 'pizza hut',
      'domino', "domino's", 'papa john', 'little caesar', 'sushi',
      'restaurant', 'diner', 'grill ', 'grille ', 'steakhouse', 'bbq',
      'kitchen', 'eatery', 'bistro', 'tavern', 'brewpub', 'brewery',
    ],
    'Groceries': [
      'walmart', 'wal-mart', 'kroger', 'aldi', 'whole foods', 'trader joe',
      'safeway', 'publix', 'hy-vee', 'hyvee', 'price chopper', 'sprouts',
      'meijer', 'winco', 'food lion', 'harris teeter', 'albertsons',
      'samsclub', "sam's club", 'costco', 'bj\'s wholesale',
      'fresh market', 'natural grocers', 'aldi',
      'target', 'super target', // Target is mostly grocery/general
      'grocery', 'supermarket', 'food store', 'fresh market',
    ],

    // ── Transportation ────────────────────────────────────────────────────
    'Rideshare / Parking': [
      'uber ', 'lyft', 'parking', 'park meter', 'parkwhiz', 'spothero',
      'impark',
    ],
    'Public Transit': [
      'metro', 'transit', 'mta ', 'bart ', 'wmata', 'mbta', 'cta ',
      'bus pass', 'train ticket', 'amtrak',
    ],
    'Car Insurance': [
      'geico', 'state farm', 'allstate', 'progressive', 'usaa insurance',
      'farmers ins', 'nationwide ins', 'liberty mutual', 'car insurance',
      'auto insurance',
    ],
    'Car Payment': ['auto loan', 'car loan', 'toyota financial', 'honda financial',
      'ford motor credit', 'gm financial', 'ally financial auto',
    ],
    'Car Maintenance': [
      'jiffy lube', 'oil change', 'tire', 'firestone', 'goodyear',
      'pep boys', "o'reilly", "autozone", 'advance auto', 'napa auto',
      'midas', 'meineke', 'mavis',
    ],
    'Gas': [
      'shell', 'chevron', 'exxon', 'mobil', 'bp ', 'valero', 'sinclair',
      'quiktrip', 'qt ', "casey's", 'phillips 66', 'circle k', 'speedway',
      'marathon', 'sunoco', 'murphy', 'pilot travel', 'loves travel',
      'kwik trip', 'kwiktrip', 'gas station', 'fuel', 'petro',
    ],

    // ── Health ────────────────────────────────────────────────────────────
    'Prescriptions': [
      'cvs pharm', 'walgreens', 'rite aid', 'walmart pharm', 'kroger pharm',
      'prescription', 'rx ', 'pharmacy',
    ],
    'Gym & Fitness': [
      'planet fitness', 'la fitness', 'anytime fitness', '24 hour fitness',
      'ymca', 'equinox', 'orange theory', 'orangetheory', 'crossfit',
      'peloton', 'gym', 'fitness',
    ],
    'Doctor / Dentist': [
      'dr ', 'md ', 'clinic', 'hospital', 'medical', 'dental', 'dentist',
      'orthodont', 'urgent care', 'er visit', 'radiology', 'lab corp',
      'quest diag', 'eye care', 'vision center',
    ],
    'Health Insurance': [
      'health ins', 'bcbs', 'blue cross', 'aetna', 'cigna', 'humana',
      'united health', 'anthem', 'kaiser',
    ],
    'Vision & Dental': [
      'vision works', 'lenscrafters', 'warby parker', 'glasses', 'contacts',
      'vision ins', 'dental ins',
    ],

    // ── Personal ─────────────────────────────────────────────────────────
    'Subscriptions': [
      'netflix', 'hulu', 'disney+', 'disneyplus', 'hbomax', 'max ',
      'paramount+', 'apple tv', 'spotify', 'apple music', 'youtube premium',
      'amazon prime', 'audible', 'kindle', 'sirius', 'siriusxm',
      'adobe', 'microsoft 365', 'google one', 'dropbox', 'icloud',
      'duolingo', 'headspace', 'calm', 'nytimes', 'wsj ',
    ],
    'Entertainment': [
      'amc theatre', 'regal cinema', 'cinemark', 'fandango', 'ticketmaster',
      'eventbrite', 'live nation', 'bowling', 'minigolf', 'arcade',
      'dave & buster', 'escape room', 'laser tag',
    ],
    'Personal Care': [
      'great clips', 'supercuts', 'sport clips', 'haircut', 'salon',
      'barbershop', 'nail ', 'spa ', 'ulta', 'sephora', 'bath & body',
      "bath&body", 'lush ',
    ],
    'Clothing': [
      'old navy', 'gap ', 'banana republic', 'h&m', 'zara', 'forever 21',
      'express ', 'american eagle', 'hollister', 'abercrombie',
      'nordstrom', 'macys', "macy's", 'tj maxx', 'tjmaxx', 'marshall',
      'ross stores', 'burlington', 'kohls', "kohl's", 'jcpenney',
      'clothing', 'apparel', 'fashion',
    ],
    'Books & Education': [
      'amazon kindle', 'barnes noble', "barnes & noble", 'booksamillion',
      'chegg', 'coursera', 'udemy', 'skillshare', 'masterclass',
      'tuition', 'university', 'college fee', 'textbook',
    ],
    'Hobbies': [
      'hobby lobby', 'michaels ', 'joann', 'jo-ann', 'petsmart',
      'petco', 'pet supplies', 'bass pro', 'cabelas', "cabela's",
      'dicks sporting', "dick's sporting", 'rei ', 'patagonia',
      'amazon', 'amzn', 'ebay', 'etsy', 'wayfair', 'overstock', 'wish ',
    ],

    // ── Kids ─────────────────────────────────────────────────────────────
    'Childcare': ['daycare', 'child care', 'babysit', 'kinder care', 'bright horizons'],
    'School & Supplies': [
      'school fee', 'school supply', 'staples', 'office depot',
      'officemax', 'back to school',
    ],
    'Activities & Sports': [
      'soccer', 'baseball', 'basketball', 'swimming lesson', 'dance class',
      'gymnastics', 'karate', 'piano lesson', 'sport registration',
    ],

    // ── Savings ───────────────────────────────────────────────────────────
    '401k / Retirement': ['401k', '403b', 'retirement contrib', 'fidelity', 'vanguard', 'schwab'],
    'HSA Contribution': ['hsa ', 'health savings'],
    '529 / College Savings': ['529 ', 'college savings', 'edvest', 'bright start'],

    // ── Gifts & Donations ────────────────────────────────────────────────
    'Charitable Donations': [
      'donate', 'donation', 'charity', 'nonprofit', 'red cross',
      'salvation army', 'goodwill', 'habitat for humanity', 'peta',
      'humane society', 'st jude', 'united way',
    ],
    'Gifts': ['1800flowers', 'ftd ', 'teleflora', 'hallmark', 'gift shop'],

    // ── Taxes ─────────────────────────────────────────────────────────────
    'Taxes': ['irs ', 'tax payment', 'state tax', 'county tax', 'property tax', 'turbo tax'],

  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the best-matching category ID for [description], or null if no
  /// rule matches. Pass [isIncome]=true for positive-amount transactions.
  String? match(String description, {required bool isIncome}) {
    final lower = description.toLowerCase();
    final rules = isIncome ? _incomeRules : _expenseRules;

    for (final entry in rules.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return _idForName(entry.key);
        }
      }
    }
    return null;
  }

  String? _idForName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name).id;
    } catch (_) {
      return null;
    }
  }
}
