import '../models/article.dart';

/// Static sample content transcribed from the Stitch HTML mockups, so every
/// screen renders something recognizable out of the box. Replace with real
/// repository calls to your backend when wiring up data.
class MockData {
  MockData._();

  static const heroStory = Article(
    id: 'hero-1',
    category: 'POLITICS',
    title:
        'The New Guard: How a tectonic shift in regional alliances is reshaping the 2024 landscape',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuChfqL-OzoisoTeu1si7CYViuOZ-GZZuZUu12ypV90bfqaDSruoyaXKFJzxs1VEZ-nVCO7_fvMokr8VOd6JDPUCgU44OtFY0_aC-gRjeGNkMsxPk1O2sZys9CdEddqS5UUgkCazNMmlp72MDl_1ojOcq7qKA6rzPfbsvm3tmuyiGwYsOu9hR30Yn1dAwshJRfefT2pQp8XYlM_yIonfa9o4qNDU__-3mHo0CT4VpZzUkzGLZ9utoadt',
    author: 'By Jyoti Malhotra',
    readTime: '8 mins read',
  );

  static const secondaryStories = [
    Article(
      id: 'sec-1',
      category: 'Economy',
      title: 'Infrastructure push: \$2.4B allocated for high-speed corridors',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAU88ZqCPk10i3taxx5Sug_MTQOczQyXXW47hOVh4FaGiGygEES1TeZtJBicyMRPNFrYVCfnKuoBBwArCmxRUdSP9d1DVFw4uxbVx-qgfl4TkzIfxKLQUBmpt88EbxJnVxfEAnzzhzMPWOSFQCQZa0AcoBkbX2jCrYbudkN6luoiet39kVhz34xrmrfysRSXNBXyYXysPglE9hfVSKVhJAGr7mY8N5grUYZu-IG_hRaXYT8YWUQOu7n',
      author: 'Banana Ganrajya Team',
    ),
    Article(
      id: 'sec-2',
      category: 'Tech',
      title: "The Silicon Race: Why India's chip dreams are closer than ever",
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCcWfWQP_AyeflHRfOFCMTVHjRo0xIbhlugDlc-ERL101f4N7-BXsogP0gF_Khi9L0NNRSGEco0J7yB4ipFNbLgOesgHLcbqvxrYIa-Ul03YnC07TPmfTMUnY00wPWE0XKV9VRrvFPiFM_nuRHByuGYBjJDyZIPzTjREpH16UtZzfZL32mWM383yHpJGOtdjPNOHwbqvSIfZ8iVgmcEZE_HU4fnyUEomQz0BYJk23kQUkkVz5Mz8xcd',
      author: 'Banana Ganrajya Team',
    ),
  ];

  static const groundReports = [
    Article(
      id: 'gr-1',
      category: 'Diplomacy',
      title: "How the G20 legacy is shaping India's new trade routes",
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBPXrLDM7Wr31ud2zEcRtX4zhjcvbNC89u40PswK-dO4coW8bSBfATYbV9x9s8IDw7ZPgqCmZFliU5flbCWeG7cVyOjDtKuOxkJFJTJcNoY14XeQR72FyR596DM6Xylee1x3ool5Je14Z6cV2DpKQD9-SxxFBo2hOYBzmn6xU5M9pvA4dfScxL-B8mdd4KlqEMW0TaCASsgkNllN_Yyp24L3katNGiUFvPyDWkvWvdNMBoRjY44aIFf',
      author: 'Banana Ganrajya Team',
      readTime: '12 mins read',
      timeAgo: '2 hours ago',
    ),
    Article(
      id: 'gr-2',
      category: 'Environment',
      title: 'Glacial retreat in the Himalayas: A warning from the heights',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDd7VM9NDxa2u7VixKahvak191_y07zpqqMAMAx4fTeF_gBq1ajskLbXypV_VtnaIlRmoW-XktOwlnKXWwH2ZeoafwVDQC1HDDjygEP07h1huq10JSCMjvo6dePJOeyfN1FY8EMLXIU9Xw_GT_vHsNfURzmFqfzlf3H4bUrEw2oTptu6pOO9tgeRFcKy53O0ZfZmgC6XCBHMfs5ZByypwrPXd3G-3oYtXDpBoWldHb79mQN64L-KfyS',
      author: 'Banana Ganrajya Team',
      readTime: '15 mins read',
      timeAgo: '5 hours ago',
    ),
    Article(
      id: 'gr-3',
      category: 'Science',
      title: "ISRO's next leap: Preparing for the Shukrayaan mission",
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCrl5AQm8AcKQ8ysY4mgQrVS8-ZHUILUeAA6X-jYidY6UTb9qT_m-lq3aqLZXbHuJINZRxsBixSQtYU2z0qgOXy7CxzlVeTLs_kw4NbT6N7EvZ75dkdRBD-LQUilKGeqgCDJPi5Cwstm4sJ3AG8E7CZaU4s8FKhubwpJRikidA6gI4rk5lHu2d69fd6aVUSe3ZOhbLnxuHLiBWE1e3sCTuu2ytJFBBDxMO6X9Ja5tyHYWs0L0LLZn9C',
      author: 'Banana Ganrajya Team',
      readTime: '6 mins read',
      timeAgo: 'Yesterday',
    ),
  ];

  static const fineprintFeatured = Article(
    id: 'fp-featured',
    category: 'Premium Deep Dive',
    title: 'The Hidden Architecture of Power: Inside the New Policy Chambers',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB3kKjVuDY2rY9AIeW7FcOZtK3P-hpuNxU_LmWEju_uW_HoTSS7T2br87qR4TYNbonLpT3SpMLexiW6ktJc7P4fraqDtLtH8wPkNCED-_IEbRsuFvhSaQRVokxkP9mjuS8bhTI_lh5cK-oWeVAEMUocMUAXcFaTxJ7yjSJRuWVEhA5XMsNLC9jHBOQI9JiISQMejMk9wKht9ugKiqTn_IXDp_WhCSCsOA6HFxK_SlwT_xSQREBdyzLx',
    author: 'By Jyoti Malhotra • 12 min read',
    isPremium: true,
  );

  static const fineprintList = [
    Article(
      id: 'fp-1',
      category: 'Investigation',
      title: 'The Water Mafia of Bundelkhand: A 6-Month FinePrint Audit',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBPXnQ-PfdNlbU51U9YXRM14h-CMKLKRuXG9xaKO6wkAd2TuaOoZqKrGjA2NBFNEfyLbNEt290n02sGXghV2zoSQsiPNhHe7OmTpUg8t49UWvEB4fknCMyjDBJJ2tXA76z7IQj7KDPGbezlSMjdthqDL6IZjqSN4MYs9uNEUIWMBQ8obAI4oD-bzjypUDegRpH903n7xtPGlqBBIhy9DhGoDcgbgyK9xWF07MEM_I27LKSEI-qv8aaf',
      author: 'Banana Ganrajya Team',
      timeAgo: '6 hours ago • Exclusive',
    ),
    Article(
      id: 'fp-2',
      category: 'Deep Dive',
      title: "Silicon Valley's New Lobby in Lutyens' Delhi",
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC_PLzUNX6YajlGvXMYHR8OsrZoXwNrBMa6DhEJo327UwP1GHCvtgw97vpPVQ7_6sz2cyNsL57g6LYEJ2huk0G6EVF0Y8wMe07Oxqj9hOiO3n0Cg7QOvPpVxMZXDtYbBAgJf_QEToyAk58IGCfnz6HUTuR_I1Mokgg9QaK4yQqGNPT_y3rnhPu-e3l1CmDHc3At8oe7F6G-FIQCtUwCKGJO2WjCBXWi5kZWHWnJja7dwAGG03MAob7w',
      author: 'Banana Ganrajya Team',
      timeAgo: 'Yesterday • Long Read',
    ),
    Article(
      id: 'fp-3',
      category: 'Security',
      title: "The Digital Silk Road: China's Tech Footprint in the Subcontinent",
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAYy9zQAnHywjWoSBSu4SZaKf_zJtOEhHOPP5-adgqyQXwpcmFw1S17f6j1P9juB1iy9tg7HeiLugnYF7PQo31nUWVqZcqoJSvPlF8B78yVFnVsxBdxeyZzr69r8GafO3s1I7Y1gO2RMgmHOLsmwD_Rx6aWRfkD9bFC5iHkDx23Qr7GFSdL9ZmvJOJvV7SYCqBExI2q5J4EEVVd3wGYm7F9rg7vgcIuT2oEPLNq29JEM1udrQdkSqZ4',
      author: 'Banana Ganrajya Team',
      timeAgo: '2 days ago • Intelligence Report',
      isLocked: true,
    ),
  ];

  static const opinionFeatured = Article(
    id: 'op-featured',
    category: "Editor's Choice",
    title: 'Why the hyphenated identity is failing the modern voter.',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAXv9mAK9NaMVidUXdLk9XTu8dA38e6XU3yw-PmJxCIKF8e9tXkdK6Ndk-ovFDE56-55uXTYGWcwE7t78fBrfuQZvfE4AeB2QBhcP_Zzq65x1zh5uqw8BMkSvvZ-R5F_6O9ds2MGz-wlaesURCkWUta4Dr7eWhsAw_a8XEcJCbkzF8K1Ab6iDeonKvO5Li44777S9VIHT0_Xu7ngxLX80241Og90YKk2HgOje4mmtB97ov0HiY7g3jd',
    author: 'Dr. Aruna Singh',
    readTime: '8 min read • 2h ago',
    excerpt:
        'Politics today is obsessed with labels. But as we move toward a more integrated economy, these silos are becoming obsolete.',
  );

  static const opinionRows = [
    Article(
      id: 'op-1',
      category: 'Economy',
      title: "The myth of the 'Soft Landing' and what it means for your savings.",
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAvMZq55XQmx1WBYMl64Pv2iIGEiSRiBQx6Ra5fNfFP9yL92tNlODh7aZQEhuLWDu44_Ckx_bQMFfoDGrdeTY3ZYA-fQhNXfL7OWzEOUrDl4PoYNc3uQqUUmiLME9ljh4B4WnfP_COPMKPI2mt_xOVCBSCl2IGY96onfq3z9VOEarXt0SQ1zW8hEk-fJ0ymKij5NXqTNWvefmnUuFdJ8sHKV_27IgAdxU5khwg9ZtNWt6mLMbW8Dq-h',
      author: 'Vikram Sethi',
      readTime: '5 min read',
    ),
    Article(
      id: 'op-2',
      category: 'Foreign Policy',
      title: 'Neutrality is no longer an option in the new cold war.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCG4LqxlUiUXAjb2TFFu_CP-Juzl7R3SNdawGWrPpNe-kX2lvG5vOVGbta5pJ2I3sD39nSX2CEz0-M0utLBhj27-QHJ9AEWARrjBbCK0odVdimzH1JUzQHHajYOSupO1iEsy8_xIn02-lp0-IjgfMy2fQPZCfvLLCVtlyanhBd4DF8XgWt9D15JlzZKNhJOKcFHzZCxSH4ctnQUdeUrBSJbKR74_RW59CkcVNDi-cdvNlei1jo-1pxy',
      author: 'Meera Nair',
      readTime: '12 min read',
    ),
    Article(
      id: 'op-3',
      category: 'Society',
      title: 'Urban loneliness is the silent epidemic of the 21st century.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAv9g5Kb3PF5d7hLmeQq8d7gWA99TuSN_qDHyxyWV6RdRQKvkC2Pu5--PFfu1QzEGl_Lfl-tBJ7jsUyeTE4SoUrmjW76xT_7XCURSmBM4KEy_ew2zghdrjwfNUDUpKpDr7aY2V6ptcoJFDZqSQNLf2SdtAD0R-vNOmlNmPm5AdMrHNAIPUuT3c2nqOw3wWv9p2i9cQ5bQIzxjeCncGl1v29ZSnyMqM3yExeXixGl9nDepQiOOish3PZ',
      author: 'Sanjay Kapoor',
      readTime: '7 min read',
    ),
  ];

  static const columnistAvatars = <String, String>{
    'Rohan Varma':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuATd5WhVbsAXJUsMOCz5F6NshPdxLYmUZhfcEaClWVl4PYI38uH1ZdBdCVmYpTw63EPoGvBplrhJ-GNeKqOpHWlBVjA3PHMoF2BOYcGiyZEk_ksXk0JhOsMyBIQVw9msOsl9CcxYEhcetZd3hZgXXw8hiT7oNd284bnfk7lMOu8MoRiCFNbak1Yv_wauDTEZFZIG2GpctNP5-87K0XE37o4Ss88NLzVwh5PqYoyM6vonO9r_caqktLA',
    'Anjali Gupta':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB-RYK4rGro5iDrR69lYonaMWIVRUxrOBUARNulhYUBbpGEon38Gyep31hWetdRbWh3vLPXD_w-9cfahJO-wwYlqMBAttnQtM1GuzonimGZTOZhOmRCgfTI6vmmXuyNnn04geeIi07BvazEfaTPJTDv6cjxcV032FyXBBXEM6MYaioh8x1MBL8Uh_JrlAT_qOa7jSesYZT9t4AK56LsnI_fMCWdylIuz10bu_ymCrKWK-xfB_AotKWn',
    'Prof. K. Iyer':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAdFxAr5-eRPVolwMJ_X7JzzFV9GxABNpzWwmpSViyOqvXm_fHXbtA_Z-awF-LvE4bYJ26CuTBi6R_l1fOqO1-cT1Pf8eH_q5oZSX9k2ei4p473qXpKKOHDSG2h-BvdXSdxp1yCmjzp3dLLnexVH3ZwvEllEEPGfj6ipiaNr6UyCakp4dJNQ8tq--u8t0EQDbduU8ilx67laBWaqAGPHAE-1rPdkhXmJTA7NdhT2h2biWtRMUcvc9sZ',
    'Zane Malik':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBEAARYWEQ5DCTjVzS8daRmU8j-CBITFJxrcdQ-Hy5ZHigG6U7uao2POtkf1HzjG3mABkKnK1d-_ucNOIEBiGZM4d6Pz9AkiAyAajoiNQcgAk-UJ81QvvseX8azGxXNIdjjuZg13TBHen84LDQHP_fuXGkRkpJJRpRTZgFOfvMSTLOF9-zgxZiS4nma0xbnl0quGJHZAyzVDs152PJ1hHCWeKZw8WVrsRKyKS0TPVmhsyiM7Sq1-Lzl',
  };

  static const articleAuthorAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBQMeNNrKemoLBLC8YpfonmZduB-CFzexmW0Fj7nILHqx4y9HXpL4RzhB8UNB_VR13EZ9iCwlPiU25Uc5dHhewfebOrZgjcRoZxODL3mTpGpY0X5-abDPVDGnGOHs17gbSy9jEiqIlGdfBut3KkLqy_7duFCo5FsZEKwoH0d791cRBLeZuRiOtdqoFSwHXMgtkxs9C4JXFkmHxlwwiB-4wOyjWqqbgbengJFcNrGAjwYWEvRtNn7W4F';

  static const articleFeatureImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBAk88hLRBSD7fFN1RbNHXFl4nhj-Hy76bOB_ROUXS4ScFYkyImF3sSkAg2SzBw57BqRnOxYfEdaWV3mgxiCxZM63WGN-YV1Z7uUXnilbIdYB37sgxrBzSmhroDbIsGQ73epiWpS2yMBd4pQZhd0z1DUb7snY-QSbifBlOFoCYHBITuuH_bV-8xhcLk1TSjwwv2tVEd6dVhy_KBYRLNZROJulIzh300skpv8nF0r6FkutplaZpU6u1k';
}
