from datetime import datetime
from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine
from app.db.models import Author, Article, Tag, User, Comment

def seed_database():
    db: Session = SessionLocal()
    try:
        # Check if database is already seeded
        if db.query(Article).count() > 0:
            print("Database already seeded.")
            return

        print("Seeding database...")

        # 1. Create Authors
        authors = {
            "jyoti_malhotra": Author(
                id="jyoti_malhotra",
                name="Jyoti Malhotra",
                title="Senior Associate Editor",
                bio="Jyoti Malhotra is a senior journalist with over three decades of experience reporting on foreign policy, domestic politics, and regional alliances.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuBQMeNNrKemoLBLC8YpfonmZduB-CFzexmW0Fj7nILHqx4y9HXpL4RzhB8UNB_VR13EZ9iCwlPiU25Uc5dHhewfebOrZgjcRoZxODL3mTpGpY0X5-abDPVDGnGOHs17gbSy9jEiqIlGdfBut3KkLqy_7duFCo5FsZEKwoH0d791cRBLeZuRiOtdqoFSwHXMgtkxs9C4JXFkmHxlwwiB-4wOyjWqqbgbengJFcNrGAjwYWEvRtNn7W4F"
            ),
            "aruna_singh": Author(
                id="aruna_singh",
                name="Dr. Aruna Singh",
                title="Contributing Columnist & Sociologist",
                bio="Dr. Aruna Singh is a leading political sociologist and author of 'The Fractured Vote'. She writes extensively on caste, gender, and electoral alliances.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuB-RYK4rGro5iDrR69lYonaMWIVRUxrOBUARNulhYUBbpGEon38Gyep31hWetdRbWh3vLPXD_w-9cfahJO-wwYlqMBAttnQtM1GuzonimGZTOZhOmRCgfTI6vmmXuyNnn04geeIi07BvazEfaTPJTDv6cjxcV032FyXBBXEM6MYaioh8x1MBL8Uh_JrlAT_qOa7jSesYZT9t4AK56LsnI_fMCWdylIuz10bu_ymCrKWK-xfB_AotKWn"
            ),
            "vikram_sethi": Author(
                id="vikram_sethi",
                name="Vikram Sethi",
                title="Financial Analyst & Economist",
                bio="Vikram Sethi is a columnist who specializes in macroeconomic policies, fiscal structures, and financial market analysis.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuATd5WhVbsAXJUsMOCz5F6NshPdxLYmUZhfcEaClWVl4PYI38uH1ZdBdCVmYpTw63EPoGvBplrhJ-GNeKqOpHWlBVjA3PHMoF2BOYcGiyZEk_ksXk0JhOsMyBIQVw9msOsl9CcxYEhcetZd3hZgXXw8hiT7oNd284bnfk7lMOu8MoRiCFNbak1Yv_wauDTEZFZIG2GpctNP5-87K0XE37o4Ss88NLzVwh5PqYoyM6vonO9r_caqktLA"
            ),
            "meera_nair": Author(
                id="meera_nair",
                name="Meera Nair",
                title="Strategic Affairs Columnist",
                bio="Meera Nair is an international security specialist analyzing shifts in diplomatic alliances and maritime policy.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAdFxAr5-eRPVolwMJ_X7JzzFV9GxABNpzWwmpSViyOqvXm_fHXbtA_Z-awF-LvE4bYJ26CuTBi6R_l1fOqO1-cT1Pf8eH_q5oZSX9k2ei4p473qXpKKOHDSG2h-BvdXSdxp1yCmjzp3dLLnexVH3ZwvEllEEPGfj6ipiaNr6UyCakp4dJNQ8tq--u8t0EQDbduU8ilx67laBWaqAGPHAE-1rPdkhXmJTA7NdhT2h2biWtRMUcvc9sZ",
            ),
            "sanjay_kapoor": Author(
                id="sanjay_kapoor",
                name="Sanjay Kapoor",
                title="Public Health & Urban Affairs Columnist",
                bio="Sanjay Kapoor writes about urban design, silent epidemics, environmental policy, and metropolitan infrastructure.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuBEAARYWEQ5DCTjVzS8daRmU8j-CBITFJxrcdQ-Hy5ZHigG6U7uao2POtkf1HzjG3mABkKnK1d-_ucNOIEBiGZM4d6Pz9AkiAyAajoiNQcgAk-UJ81QvvseX8azGxXNIdjjuZg13TBHen84LDQHP_fuXGkRkpJJRpRTZgFOfvMSTLOF9-zgxZiS4nma0xbnl0quGJHZAyzVDs152PJ1hHCWeKZw8WVrsRKyKS0TPVmhsyiM7Sq1-Lzl"
            ),
            "banana_team": Author(
                id="banana_team",
                name="Banana Ganrajya Team",
                title="Editorial Board",
                bio="Articles contributed collectively by the investigative reporting desk, editors, and correspondents of Banana Ganrajya.",
                avatar_s3_key="https://assets.banana.in/wp-content/uploads/2018/01/banana_favicon.png"
            )
        }

        # Sibling Columnists to complete the Columnist Gallery row (Opinion Screen)
        extra_columnists = [
            Author(
                id="rohan_varma",
                name="Rohan Varma",
                title="Foreign Policy Fellow",
                bio="Rohan writes on neighborhood diplomacy and trade corridors.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuATd5WhVbsAXJUsMOCz5F6NshPdxLYmUZhfcEaClWVl4PYI38uH1ZdBdCVmYpTw63EPoGvBplrhJ-GNeKqOpHWlBVjA3PHMoF2BOYcGiyZEk_ksXk0JhOsMyBIQVw9msOsl9CcxYEhcetZd3hZgXXw8hiT7oNd284bnfk7lMOu8MoRiCFNbak1Yv_wauDTEZFZIG2GpctNP5-87K0XE37o4Ss88NLzVwh5PqYoyM6vonO9r_caqktLA"
            ),
            Author(
                id="anjali_gupta",
                name="Anjali Gupta",
                title="Judicial Affairs Correspondent",
                bio="Anjali Gupta writes on supreme court rulings, civil rights, and constitutional law.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuB-RYK4rGro5iDrR69lYonaMWIVRUxrOBUARNulhYUBbpGEon38Gyep31hWetdRbWh3vLPXD_w-9cfahJO-wwYlqMBAttnQtM1GuzonimGZTOZhOmRCgfTI6vmmXuyNnn04geeIi07BvazEfaTPJTDv6cjxcV032FyXBBXEM6MYaioh8x1MBL8Uh_JrlAT_qOa7jSesYZT9t4AK56LsnI_fMCWdylIuz10bu_ymCrKWK-xfB_AotKWn"
            ),
            Author(
                id="prof_k_iyer",
                name="Prof. K. Iyer",
                title="Visiting Professor of Geopolitics",
                bio="Prof. Iyer focuses on energy security, global supply chains, and Indo-Pacific logistics.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAdFxAr5-eRPVolwMJ_X7JzzFV9GxABNpzWwmpSViyOqvXm_fHXbtA_Z-awF-LvE4bYJ26CuTBi6R_l1fOqO1-cT1Pf8eH_q5oZSX9k2ei4p473qXpKKOHDSG2h-BvdXSdxp1yCmjzp3dLLnexVH3ZwvEllEEPGfj6ipiaNr6UyCakp4dJNQ8tq--u8t0EQDbduU8ilx67laBWaqAGPHAE-1rPdkhXmJTA7NdhT2h2biWtRMUcvc9sZ"
            ),
            Author(
                id="zane_malik",
                name="Zane Malik",
                title="Tech & Security Essayist",
                bio="Zane Malik writes on state-sponsored cyber warfare, data algorithms, and geopolitical code.",
                avatar_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuBEAARYWEQ5DCTjVzS8daRmU8j-CBITFJxrcdQ-Hy5ZHigG6U7uao2POtkf1HzjG3mABkKnK1d-_ucNOIEBiGZM4d6Pz9AkiAyAajoiNQcgAk-UJ81QvvseX8azGxXNIdjjuZg13TBHen84LDQHP_fuXGkRkpJJRpRTZgFOfvMSTLOF9-zgxZiS4nma0xbnl0quGJHZAyzVDs152PJ1hHCWeKZw8WVrsRKyKS0TPVmhsyiM7Sq1-Lzl"
            )
        ]

        # Save authors to database
        for author in list(authors.values()) + extra_columnists:
            db.add(author)
        db.commit()

        # 2. Add sample Articles
        articles_to_seed = [
            # Breaking News Story
            Article(
                id="breaking-1",
                category="POLITICS",
                title="Supreme Court initiates suo motu proceedings on major constitutional reform",
                excerpt="The three-judge bench headed by the Chief Justice of India scheduled hearings to determine the validity of the updated regional devolution act.",
                body="The Supreme Court of India has initiated a landmark suo motu proceeding to examine the constitutional validity of the recently enacted Regional Devolution Act.\n\n"
                     "Headed by the Chief Justice, the three-judge bench scheduled emergency public hearings commencing next Tuesday. Legal experts suggest that this case represents a critical test for the core principles of cooperative federalism that have guided center-state relations for over half a century.\n\n"
                     "The proceedings arose after multiple state governments raised severe concerns regarding the fiscal devolution formulas, claiming that recent amendments infringe on state financial autonomy.\n\n"
                     "Attorney General representatives have defended the act, stating it ensures unified macroeconomic stability during global trade recessions. Savers and regional leaders alike are watching the development with deep interest.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuChfqL-OzoisoTeu1si7CYViuOZ-GZZuZUu12ypV90bfqaDSruoyaXKFJzxs1VEZ-nVCO7_fvMokr8VOd6JDPUCgU44OtFY0_aC-gRjeGNkMsxPk1O2sZys9CdEddqS5UUgkCazNMmlp72MDl_1ojOcq7qKA6rzPfbsvm3tmuyiGwYsOu9hR30Yn1dAwshJRfefT2pQp8XYlM_yIonfa9o4qNDU__-3mHo0CT4VpZzUkzGLZ9utoadt",
                author_id="banana_team",
                read_time_minutes=4,
                time_ago="Just Now"
            ),
            # Home Page - Hero Story
            Article(
                id="hero-1",
                category="POLITICS",
                title="The New Guard: How a tectonic shift in regional alliances is reshaping the 2024 landscape",
                excerpt="Electoral battles are increasingly dominated by fluid local adjustments. Understanding the structural shift that binds state and national leaders in this new security framework.",
                body="The Indian political landscape is undergoing a silent transformation. Over the past six months, behind-the-scenes negotiations, unusual coalitions, and tactical local alignments have begun redrawing maps that once seemed rigid.\n\n"
                     "For generations, regional satraps maintained hard ideological boundaries. Yet today, macroeconomic shifts, localized anti-incumbency, and dynamic voter behaviors are pushing traditional political rivals into unexpected partnerships.\n\n"
                     "Analysts point out that these fluid regional adjustments are not merely transactions; they represent a fundamental, structural transformation of the electoral framework. High-ranking leaders from opposing sides are actively cooperating to preserve their turf, setting up a complex, multi-tiered chess game for 2024.\n\n"
                     "What this means for the average voter is a blurring of lines between state aspirations and national security narratives. As broadsheets report on massive infrastructure investments, the real political energy is concentrated in small-room committee updates where future power sharing formulas are being hashed out.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuChfqL-OzoisoTeu1si7CYViuOZ-GZZuZUu12ypV90bfqaDSruoyaXKFJzxs1VEZ-nVCO7_fvMokr8VOd6JDPUCgU44OtFY0_aC-gRjeGNkMsxPk1O2sZys9CdEddqS5UUgkCazNMmlp72MDl_1ojOcq7qKA6rzPfbsvm3tmuyiGwYsOu9hR30Yn1dAwshJRfefT2pQp8XYlM_yIonfa9o4qNDU__-3mHo0CT4VpZzUkzGLZ9utoadt",
                author_id="jyoti_malhotra",
                read_time_minutes=8,
                time_ago="2h ago"
            ),
            # Home Page - Secondary Stories
            Article(
                id="sec-1",
                category="Economy",
                title="Infrastructure push: $2.4B allocated for high-speed corridors",
                excerpt="New industrial logistics and transport corridors aim to dramatically reduce intra-state transit times and elevate manufacturing logistics.",
                body="The Finance Ministry has announced a massive capital outlay of $2.4 billion dedicated strictly to building five high-speed economic corridors.\n\n"
                     "This monumental funding is aimed at connecting major industrial hubs in central India with deepwater ports along the eastern coastline. Logistics analysts project that these high-speed networks will reduce shipping transit times by nearly 42%, offering a significant boost to domestic manufacturing.\n\n"
                     "Furthermore, the project expects to generate over 150,000 construction and operational jobs, bolstering regional economies that have faced persistent rural stagnation. Private sector developers have welcomed the dynamic tax structures built into the PPP framework.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAU88ZqCPk10i3taxx5Sug_MTQOczQyXXW47hOVh4FaGiGygEES1TeZtJBicyMRPNFrYVCfnKuoBBwArCmxRUdSP9d1DVFw4uxbVx-qgfl4TkzIfxKLQUBmpt88EbxJnVxfEAnzzhzMPWOSFQCQZa0AcoBkbX2jCrYbudkN6luoiet39kVhz34xrmrfysRSXNBXyYXysPglE9hfVSKVhJAGr7mY8N5grUYZu-IG_hRaXYT8YWUQOu7n",
                author_id="banana_team",
                read_time_minutes=5,
                time_ago="4h ago"
            ),
            Article(
                id="sec-2",
                category="Tech",
                title="The Silicon Race: Why India's chip dreams are closer than ever",
                excerpt="A deep dive into the recent semiconductor joint ventures and fab fabrication facilities currently rising across major industrial zones.",
                body="India's ambition to become a global hub for semiconductor manufacturing is rapidly materializing. Within the past quarter, three major joint ventures have broken ground on advanced fabrication plants.\n\n"
                     "Supported by generous state subsidies and a massive pool of specialized VLSI design engineers, these fabs represent India's first serious entry into advanced wafer processing. Experts suggest that while local manufacturing initially focuses on legacy nodes (28nm to 40nm) for automotive and IoT applications, the long-term roadmap actively plans for sub-7nm fabrication.\n\n"
                     "This technological jump secures critical supply chains, positioning India as a strategic alternative to traditional manufacturing hubs in East Asia.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuCcWfWQP_AyeflHRfOFCMTVHjRo0xIbhlugDlc-ERL101f4N7-BXsogP0gF_Khi9L0NNRSGEco0J7yB4ipFNbLgOesgHLcbqvxrYIa-Ul03YnC07TPmfTMUnY00wPWE0XKV9VRrvFPiFM_nuRHByuGYBjJDyZIPzTjREpH16UtZzfZL32mWM383yHpJGOtdjPNOHwbqvSIfZ8iVgmcEZE_HU4fnyUEomQz0BYJk23kQUkkVz5Mz8xcd",
                author_id="banana_team",
                read_time_minutes=6,
                time_ago="6h ago"
            ),
            # Home Page - Ground Reports (FinePrint Tab as well)
            Article(
                id="gr-1",
                category="Diplomacy",
                title="How the G20 legacy is shaping India's new trade routes",
                excerpt="Following the high-profile New Delhi declaration, diplomatic networks are fast-tracking multi-modal transport routes mapping direct routes to European markets.",
                body="The G20 New Delhi Declaration left a profound legacy that is currently manifesting in concrete trade infrastructure. Bilateral discussions on the Middle East-Europe economic corridor are accelerating despite geopolitical headwinds.\n\n"
                     "This multi-modal network combines deepwater shipping lanes, modernized rail networks, and dry ports, aiming to bypass congested chokepoints in traditional sea routes.\n\n"
                     "Diplomatic sources confirm that technical panels are drafting unified customs codes, standardized container clearances, and digital tracking structures. If successful, this trade framework represents the most critical strategic re-alignment in international logistics since the Suez Canal's expansion.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuBPXrLDM7Wr31ud2zEcRtX4zhjcvbNC89u40PswK-dO4coW8bSBfATYbV9x9s8IDw7ZPgqCmZFliU5flbCWeG7cVyOjDtKuOxkJFJTJcNoY14XeQR72FyR596DM6Xylee1x3ool5Je14Z6cV2DpKQD9-SxxFBo2hOYBzmn6xU5M9pvA4dfScxL-B8mdd4KlqEMW0TaCASsgkNllN_Yyp24L3katNGiUFvPyDWkvWvdNMBoRjY44aIFf",
                author_id="banana_team",
                read_time_minutes=12,
                time_ago="2 hours ago"
            ),
            Article(
                id="gr-2",
                category="Environment",
                title="Glacial retreat in the Himalayas: A warning from the heights",
                excerpt="A six-month scientific survey reveals unprecedented warming rates. What this means for river basin ecosystems supporting over 500 million lives.",
                body="An exhaustive scientific report compiled by a joint task force of glaciologists has revealed a shocking development in the Himalayan range: glaciers are retreating at double the historical average speed.\n\n"
                     "Using high-resolution satellite telemetry and field sensors, researchers tracked summer runoffs and glacial thickness across twenty key peaks. The results indicate that crucial freshwater sources are shrinking rapidly.\n\n"
                     "In the short term, this increased melting triggers high risks of glacial lake outburst floods (GLOFs) threatening downstream mountain towns. In the long term, river basin systems supporting massive agricultural output across northern plains face severe, permanent water deficits.\n\n"
                     "The report urges immediate international climate intervention and local infrastructure restructuring to manage massive environmental and demographic shifts.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuDd7VM9NDxa2u7VixKahvak191_y07zpqqMAMAx4fTeF_gBq1ajskLbXypV_VtnaIlRmoW-XktOwlnKXWwH2ZeoafwVDQC1HDDjygEP07h1huq10JSCMjvo6dePJOeyfN1FY8EMLXIU9Xw_GT_vHsNfURzmFqfzlf3H4bUrEw2oTptu6pOO9tgeRFcKy53O0ZfZmgC6XCBHMfs5ZByypwrPXd3G-3oYtXDpBoWldHb79mQN64L-KfyS",
                author_id="banana_team",
                read_time_minutes=15,
                time_ago="5 hours ago"
            ),
            Article(
                id="gr-3",
                category="Science",
                title="ISRO's next leap: Preparing for the Shukrayaan mission",
                excerpt="Following the historic success of Chandrayaan-3, the space agency directs its high-powered radars and sensors to study Venus.",
                body="Emboldened by its historic south pole landing on the moon, the Indian Space Research Organisation (ISRO) is shifting its gaze toward our neighboring planet, Venus.\n\n"
                     "Code-named 'Shukrayaan', the interplanetary mission is scheduled for a late 2028 launch window. The orbiter will carry state-of-the-art synthetic aperture radar capable of mapping the dense, perpetual sulfuric acid clouds of Venus in unprecedented detail.\n\n"
                     "The mission's scientific objectives focus on analyzing volcanic activity, studying atmospheric chemistry, and seeking answers to how Venus transformed into a runaway greenhouse oven. Collaboration proposals from NASA, ESA, and other international agencies have highlighted the deep global interest in this low-cost, high-yield scientific endeavor.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuCrl5AQm8AcKQ8ysY4mgQrVS8-ZHUILUeAA6X-jYidY6UTb9qT_m-lq3aqLZXbHuJINZRxsBixSQtYU2z0qgOXy7CxzlVeTLs_kw4NbT6N7EvZ75dkdRBD-LQUilKGeqgCDJPi5Cwstm4sJ3AG8E7CZaU4s8FKhubwpJRikidA6gI4rk5lHu2d69fd6aVUSe3ZOhbLnxuHLiBWE1e3sCTuu2ytJFBBDxMO6X9Ja5tyHYWs0L0LLZn9C",
                author_id="banana_team",
                read_time_minutes=6,
                time_ago="Yesterday"
            ),
            # Fineprint Featured (Premium Deep Dive)
            Article(
                id="fp-featured",
                category="Premium Deep Dive",
                title="The Hidden Architecture of Power: Inside the New Policy Chambers",
                excerpt="Exclusive access to the design, strategic communication suites, and high-tech policy hubs built within the updated Central Secretariat.",
                body="Beneath the limestone vaults and sandstone pillars of the newly completed Secretariat blocks lies a high-tech labyrinth designed to alter how India is governed.\n\n"
                     "This exclusive FinePrint investigation reveals the details of the 'Policy Chambers'—an underground command complex integrating real-time telemetry, cybersecurity command setups, and secure satellite communications.\n\n"
                     "Engineered to centralize data feeds from agriculture, tax collection, border security, and power grids, the facility allows senior policy makers to execute coordinated responses during crises with unprecedented agility.\n\n"
                     "Critics raise questions over the massive scale of centralization and security boundaries, while supporters argue it modernizes an outdated administrative machinery. We examine the architecture, key technical partners, and structural designs driving this power project.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuB3kKjVuDY2rY9AIeW7FcOZtK3P-hpuNxU_LmWEju_uW_HoTSS7T2br87qR4TYNbonLpT3SpMLexiW6ktJc7P4fraqDtLtH8wPkNCED-_IEbRsuFvhSaQRVokxkP9mjuS8bhTI_lh5cK-oWeVAEMUocMUAXcFaTxJ7yjSJRuWVEhA5XMsNLC9jHBOQI9JiISQMejMk9wKht9ugKiqTn_IXDp_WhCSCsOA6HFxK_SlwT_xSQREBdyzLx",
                author_id="jyoti_malhotra",
                read_time_minutes=12,
                time_ago="1 day ago",
                is_premium=True
            ),
            # Fineprint List (Investigative Reports)
            Article(
                id="fp-1",
                category="Investigation",
                title="The Water Mafia of Bundelkhand: A 6-Month FinePrint Audit",
                excerpt="How climate stress, structural inequality, and black-market cartels transformed drinking water into a scarce and expensive commodity.",
                body="In the arid expanse of Bundelkhand, water is no longer a natural resource; it is a highly organized, lethal enterprise.\n\n"
                     "A exhaustive six-month audit by the FinePrint investigative team tracked water tanker transport networks, local political patronage, and illegal borewells across fifty drought-prone villages.\n\n"
                     "We found that black-market cartels, frequently tied directly to local politicians, actively disable state-funded piped water infrastructure to maintain artificial scarcity. Villagers are forced to spend up to 25% of their daily earnings buying substandard drinking water.\n\n"
                     "This comprehensive investigation profiles the cartels, analyzes the massive environmental impact of deep borewell depletion, and reveals how community-led water conservation initiatives are fighting back.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuBPXnQ-PfdNlbU51U9YXRM14h-CMKLKRuXG9xaKO6wkAd2TuaOoZqKrGjA2NBFNEfyLbNEt290n02sGXghV2zoSQsiPNhHe7OmTpUg8t49UWvEB4fknCMyjDBJJ2tXA76z7IQj7KDPGbezlSMjdthqDL6IZjqSN4MYs9uNEUIWMBQ8obAI4oD-bzjypUDegRpH903n7xtPGlqBBIhy9DhGoDcgbgyK9xWF07MEM_I27LKSEI-qv8aaf",
                author_id="banana_team",
                read_time_minutes=10,
                time_ago="6 hours ago"
            ),
            Article(
                id="fp-2",
                category="Deep Dive",
                title="Silicon Valley's New Lobby in Lutyens' Delhi",
                excerpt="Tech giants are bypassing traditional trade channels to directly influence India's incoming AI regulations, data localization, and trust laws.",
                body="High-end tech executives, lobbyists, and policy think-tanks from Silicon Valley have set up a quiet but formidable presence in Lutyens' Delhi.\n\n"
                     "As India drafts its landmark Digital India Act and tightens AI algorithms governance, the pressure on lawmakers has reached unprecedented heights.\n\n"
                     "Unlike traditional trade lobbies, these modern tech coalitions focus on 'co-developing' safety frameworks, offering massive cloud investments, and advocating for 'open data' regimes. We analyze the lobby's key players, the core legal sticking points (such as local storage requirements and algorithm transparency), and the geopolitical implications of choosing a regulatory path closely aligned with US tech giants.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuC_PLzUNX6YajlGvXMYHR8OsrZoXwNrBMa6DhEJo327UwP1GHCvtgw97vpPVQ7_6sz2cyNsL57g6LYEJ2huk0G6EVF0Y8wMe07Oxqj9hOiO3n0Cg7QOvPpVxMZXDtYbBAgJf_QEToyAk58IGCfnz6HUTuR_I1Mokgg9QaK4yQqGNPT_y3rnhPu-e3l1CmDHc3At8oe7F6G-FIQCtUwCKGJO2WjCBXWi5kZWHWnJja7dwAGG03MAob7w",
                author_id="banana_team",
                read_time_minutes=11,
                time_ago="Yesterday"
            ),
            Article(
                id="fp-3",
                category="Security",
                title="The Digital Silk Road: China's Tech Footprint in the Subcontinent",
                excerpt="Despite formal blocks, hardware and software dependencies continue to shape regional cyber architectures.",
                body="While official policy has banned numerous high-profile Chinese apps, a quiet, hardware-level dependency continues to shape the telecom and digital infrastructure across South Asia.\n\n"
                     "This FinePrint security dossier examines how fiber-optic cables, network switches, and budget smartphone devices serve as foundational bricks of the region's cyber-architecture.\n\n"
                     "Security experts warn that this structural dependency creates latent vulnerabilities in critical national data systems. Our investigative piece traces supply chains back to Shenzhen and highlights the massive challenges India faces in achieving true tech-sovereignty.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAYy9zQAnHywjWoSBSu4SZaKf_zJtOEhHOPP5-adgqyQXwpcmFw1S17f6j1P9juB1iy9tg7HeiLugnYF7PQo31nUWVqZcqoJSvPlF8B78yVFnVsxBdxeyZzr69r8GafO3s1I7Y1gO2RMgmHOLsmwD_Rx6aWRfkD9bFC5iHkDx23Qr7GFSdL9ZmvJOJvV7SYCqBExI2q5J4EEVVd3wGYm7F9rg7vgcIuT2oEPLNq29JEM1udrQdkSqZ4",
                author_id="banana_team",
                read_time_minutes=14,
                time_ago="2 days ago",
                is_premium=True,
                is_locked=True
            ),
            # Opinion Page - Opinion Featured
            Article(
                id="op-featured",
                category="Editor's Choice",
                title="Why the hyphenated identity is failing the modern voter.",
                excerpt="Politics today is obsessed with labels. But as we move toward a more integrated economy, these silos are becoming obsolete.",
                body="For decades, political campaigns in India have relied on the comfortable math of hyphenated identities. Scholars and pollsters split constituencies into rigid demographic blocks—caste plus language, region plus religion.\n\n"
                     "Yet, as a highly integrated national economy takes shape, these traditional social silos are cracking.\n\n"
                     "A modern, highly aspirational generation of voters, raised on ubiquitous digital connections and regional migration, is beginning to reject simple labels. When a young voter in Bundelkhand cares more about semiconductor fab jobs and high-speed economic corridors than ancestral caste adjustments, the old formulas break.\n\n"
                     "Electoral strategists who refuse to recognize this shift are preparing for a battle that no longer exists. The future of democratic engagement lies in addressing voters as complex, economic entities seeking structural growth, not demographic placeholders in a spreadsheet.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAXv9mAK9NaMVidUXdLk9XTu8dA38e6XU3yw-PmJxCIKF8e9tXkdK6Ndk-ovFDE56-55uXTYGWcwE7t78fBrfuQZvfE4AeB2QBhcP_Zzq65x1zh5uqw8BMkSvvZ-R5F_6O9ds2MGz-wlaesURCkWUta4Dr7eWhsAw_a8XEcJCbkzF8K1Ab6iDeonKvO5Li44777S9VIHT0_Xu7ngxLX80241Og90YKk2HgOje4mmtB97ov0HiY7g3jd",
                author_id="aruna_singh",
                read_time_minutes=8,
                time_ago="2h ago"
            ),
            # Opinion Page - Rows
            Article(
                id="op-1",
                category="Economy",
                title="The myth of the 'Soft Landing' and what it means for your savings.",
                excerpt="Central banks claim inflation is tamed without triggering recessions. We deconstruct the fiscal reality and why savers should tread carefully.",
                body="The global financial community is currently celebrating a 'soft landing'—the delicate art of cooling down a burning economy using interest rate spikes without collapsing employment.\n\n"
                     "Yet, behind the optimistic headlines, structural inflation remains highly sticky. For the middle-class saver, this means traditional fixed-income investments continue to yield negative real returns once adjusted for actual cost of living increases.\n\n"
                     "Central bank metrics frequently underestimate the rising costs of housing, medical care, and quality education. This opinion piece argues that instead of relying on optimistic bureaucratic updates, individuals should pivot toward inflation-resistant tangible assets to protect their generational wealth.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAvMZq55XQmx1WBYMl64Pv2iIGEiSRiBQx6Ra5fNfFP9yL92tNlODh7aZQEhuLWDu44_Ckx_bQMFfoDGrdeTY3ZYA-fQhNXfL7OWzEOUrDl4PoYNc3uQqUUmiLME9ljh4B4WnfP_COPMKPI2mt_xOVCBSCl2IGY96onfq3z9VOEarXt0SQ1zW8hEk-fJ0ymKij5NXqTNWvefmnUuFdJ8sHKV_27IgAdxU5khwg9ZtNWt6mLMbW8Dq-h",
                author_id="vikram_sethi",
                read_time_minutes=5,
                time_ago="Yesterday"
            ),
            Article(
                id="op-2",
                category="Foreign Policy",
                title="Neutrality is no longer an option in the new cold war.",
                excerpt="As technology and strategic trade supply chains fracture along geopolitical faultlines, states find the middle ground rapidly vanishing.",
                body="The historical luxury of remaining non-aligned during great power rivalries is rapidly vanishing. In the modern era, national security is no longer determined solely by nuclear arsenals or active military standing; it is coded into tech supply chains, high-end algorithms, and strategic rare-earth mineral corridors.\n\n"
                     "When a state must choose where to host its national data, which 5G infrastructure to deploy, or where to source its computational chips, a middle ground simply does not exist.\n\n"
                     "Attempting to straddle both sides of the digital divide creates dangerous security vulnerabilities. This strategic essay argues that states must make explicit, long-term geopolitical alignments to secure their digital futures, even if it means sacrificing lucrative legacy trade relationships.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuCG4LqxlUiUXAjb2TFFu_CP-Juzl7R3SNdawGWrPpNe-kX2lvG5vOVGbta5pJ2I3sD39nSX2CEz0-M0utLBhj27-QHJ9AEWARrjBbCK0odVdimzH1JUzQHHajYOSupO1iEsy8_xIn02-lp0-IjgfMy2fQPZCfvLLCVtlyanhBd4DF8XgWt9D15JlzZKNhJOKcFHzZCxSH4ctnQUdeUrBSJbKR74_RW59CkcVNDi-cdvNlei1jo-1pxy",
                author_id="meera_nair",
                read_time_minutes=12,
                time_ago="2 days ago"
            ),
            Article(
                id="op-3",
                category="Society",
                title="Urban loneliness is the silent epidemic of the 21st century.",
                excerpt="How high-density housing and digital connections are paradoxically creating isolated societies. The social and infrastructural cost of ignoring this crisis.",
                body="We live in the most interconnected era in human history. Yet, inside our high-density metropolitan zones, a silent, debilitating epidemic is spreading: profound social isolation.\n\n"
                     "Modern urban design, emphasizing high-rise residential towers, private automobiles, and algorithmic delivery apps, has systematically eliminated spontaneous, non-transactional human interactions.\n\n"
                     "Our virtual neighborhoods, while highly active on social media, fail to provide the psychological safety of physical, local communities. Medical research increasingly links chronic isolation with severe cardiovascular issues, weakened immune systems, and clinical depression.\n\n"
                     "This essay argues that to combat this public health crisis, urban planners must fundamentally redesign cities to prioritize public green spaces, community centers, and pedestrian-friendly streets that encourage natural human bonds.",
                cover_image_s3_key="https://lh3.googleusercontent.com/aida-public/AB6AXuAv9g5Kb3PF5d7hLmeQq8d7gWA99TuSN_qDHyxyWV6RdRQKvkC2Pu5--PFfu1QzEGl_Lfl-tBJ7jsUyeTE4SoUrmjW76xT_7XCURSmBM4KEy_ew2zghdrjwfNUDUpKpDr7aY2V6ptcoJFDZqSQNLf2SdtAD0R-vNOmlNmPm5AdMrHNAIPUuT3c2nqOw3wWv9p2i9cQ5bQIzxjeCncGl1v29ZSnyMqM3yExeXixGl9nDepQiOOish3PZ",
                author_id="sanjay_kapoor",
                read_time_minutes=7,
                time_ago="3 days ago"
            )
        ]

        # Add articles to database
        for article in articles_to_seed:
            db.add(article)
        db.commit()

        # 3. Create Tags and associate them (Interactive Global Search)
        tags_data = ["Diplomacy", "Trade", "Elections", "Economy", "Tech", "Glaciers", "ISRO", "Silicon", "Lobbying"]
        tags_dict = {}
        for tag_name in tags_data:
            tag = Tag(name=tag_name)
            db.add(tag)
            tags_dict[tag_name] = tag
        db.commit()

        # Simple association for testing search tags
        db.query(Article).filter(Article.id == "hero-1").first().tags.append(tags_dict["Elections"])
        db.query(Article).filter(Article.id == "sec-1").first().tags.append(tags_dict["Economy"])
        db.query(Article).filter(Article.id == "sec-2").first().tags.append(tags_dict["Tech"])
        db.query(Article).filter(Article.id == "sec-2").first().tags.append(tags_dict["Silicon"])
        db.query(Article).filter(Article.id == "gr-1").first().tags.append(tags_dict["Diplomacy"])
        db.query(Article).filter(Article.id == "gr-1").first().tags.append(tags_dict["Trade"])
        db.query(Article).filter(Article.id == "gr-2").first().tags.append(tags_dict["Glaciers"])
        db.query(Article).filter(Article.id == "gr-3").first().tags.append(tags_dict["ISRO"])
        db.query(Article).filter(Article.id == "fp-2").first().tags.append(tags_dict["Lobbying"])
        db.commit()

        # 4. Create a dummy User (to support Bookmarks & Comments testing)
        dummy_user = User(
            id="auth0|mock_user_123",
            email="subscriber@banana.in",
            name="John Doe",
            tier="FREE"
        )
        db.add(dummy_user)
        db.commit()

        # 5. Create some sample Comments (to support Comments & Social testing)
        comments = [
            Comment(
                id="comment_1",
                article_id="hero-1",
                user_id="auth0|mock_user_123",
                body="An absolutely brilliant piece of reporting. The political realignment in the rural zones is indeed very dynamic.",
            ),
            Comment(
                id="comment_2",
                article_id="hero-1",
                user_id="auth0|mock_user_123",
                parent_id="comment_1",
                body="Agreed, the old caste math formulas seem highly fragile in these economic corridors.",
            )
        ]
        for c in comments:
            db.add(c)
        db.commit()

        print("Database seeding completed successfully!")
    except Exception as e:
        db.rollback()
        print(f"Error during database seeding: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
