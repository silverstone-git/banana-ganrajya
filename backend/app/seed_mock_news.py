"""Seed a batch of obviously-fake, satirical mock news articles.

Every article here is fiction: invented people, invented ministries, invented
numbers. Titles carry a "[MOCK]" prefix and every body ends with a satire
disclaimer so nobody mistakes them for real reporting.

Idempotent: authors/articles/tags are upserted by primary key / name, so it is
safe to run repeatedly (e.g. from start.sh) without duplicating rows.

    python -m app.seed_mock_news
"""
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.db.database import SessionLocal
from app.db.models import Article, Author, Tag

DISCLAIMER = (
    "\n\n---\n"
    "MOCK NEWS / SATIRE: This article is entirely fictional and was generated as "
    "placeholder content for the Banana Ganrajya demo app. No ministers, pigeons, "
    "potholes or cows were harmed, consulted, or real."
)

# Reuse cover images already in use by the base seed so every card renders.
IMG = {
    "politics": "https://lh3.googleusercontent.com/aida-public/AB6AXuChfqL-OzoisoTeu1si7CYViuOZ-GZZuZUu12ypV90bfqaDSruoyaXKFJzxs1VEZ-nVCO7_fvMokr8VOd6JDPUCgU44OtFY0_aC-gRjeGNkMsxPk1O2sZys9CdEddqS5UUgkCazNMmlp72MDl_1ojOcq7qKA6rzPfbsvm3tmuyiGwYsOu9hR30Yn1dAwshJRfefT2pQp8XYlM_yIonfa9o4qNDU__-3mHo0CT4VpZzUkzGLZ9utoadt",
    "economy": "https://lh3.googleusercontent.com/aida-public/AB6AXuAU88ZqCPk10i3taxx5Sug_MTQOczQyXXW47hOVh4FaGiGygEES1TeZtJBicyMRPNFrYVCfnKuoBBwArCmxRUdSP9d1DVFw4uxbVx-qgfl4TkzIfxKLQUBmpt88EbxJnVxfEAnzzhzMPWOSFQCQZa0AcoBkbX2jCrYbudkN6luoiet39kVhz34xrmrfysRSXNBXyYXysPglE9hfVSKVhJAGr7mY8N5grUYZu-IG_hRaXYT8YWUQOu7n",
    "tech": "https://lh3.googleusercontent.com/aida-public/AB6AXuCcWfWQP_AyeflHRfOFCMTVHjRo0xIbhlugDlc-ERL101f4N7-BXsogP0gF_Khi9L0NNRSGEco0J7yB4ipFNbLgOesgHLcbqvxrYIa-Ul03YnC07TPmfTMUnY00wPWE0XKV9VRrvFPiFM_nuRHByuGYBjJDyZIPzTjREpH16UtZzfZL32mWM383yHpJGOtdjPNOHwbqvSIfZ8iVgmcEZE_HU4fnyUEomQz0BYJk23kQUkkVz5Mz8xcd",
    "diplomacy": "https://lh3.googleusercontent.com/aida-public/AB6AXuBPXrLDM7Wr31ud2zEcRtX4zhjcvbNC89u40PswK-dO4coW8bSBfATYbV9x9s8IDw7ZPgqCmZFliU5flbCWeG7cVyOjDtKuOxkJFJTJcNoY14XeQR72FyR596DM6Xylee1x3ool5Je14Z6cV2DpKQD9-SxxFBo2hOYBzmn6xU5M9pvA4dfScxL-B8mdd4KlqEMW0TaCASsgkNllN_Yyp24L3katNGiUFvPyDWkvWvdNMBoRjY44aIFf",
    "environment": "https://lh3.googleusercontent.com/aida-public/AB6AXuDd7VM9NDxa2u7VixKahvak191_y07zpqqMAMAx4fTeF_gBq1ajskLbXypV_VtnaIlRmoW-XktOwlnKXWwH2ZeoafwVDQC1HDDjygEP07h1huq10JSCMjvo6dePJOeyfN1FY8EMLXIU9Xw_GT_vHsNfURzmFqfzlf3H4bUrEw2oTptu6pOO9tgeRFcKy53O0ZfZmgC6XCBHMfs5ZByypwrPXd3G-3oYtXDpBoWldHb79mQN64L-KfyS",
    "science": "https://lh3.googleusercontent.com/aida-public/AB6AXuCrl5AQm8AcKQ8ysY4mgQrVS8-ZHUILUeAA6X-jYidY6UTb9qT_m-lq3aqLZXbHuJINZRxsBixSQtYU2z0qgOXy7CxzlVeTLs_kw4NbT6N7EvZ75dkdRBD-LQUilKGeqgCDJPi5Cwstm4sJ3AG8E7CZaU4s8FKhubwpJRikidA6gI4rk5lHu2d69fd6aVUSe3ZOhbLnxuHLiBWE1e3sCTuu2ytJFBBDxMO6X9Ja5tyHYWs0L0LLZn9C",
    "investigation": "https://lh3.googleusercontent.com/aida-public/AB6AXuBPXnQ-PfdNlbU51U9YXRM14h-CMKLKRuXG9xaKO6wkAd2TuaOoZqKrGjA2NBFNEfyLbNEt290n02sGXghV2zoSQsiPNhHe7OmTpUg8t49UWvEB4fknCMyjDBJJ2tXA76z7IQj7KDPGbezlSMjdthqDL6IZjqSN4MYs9uNEUIWMBQ8obAI4oD-bzjypUDegRpH903n7xtPGlqBBIhy9DhGoDcgbgyK9xWF07MEM_I27LKSEI-qv8aaf",
    "opinion": "https://lh3.googleusercontent.com/aida-public/AB6AXuAv9g5Kb3PF5d7hLmeQq8d7gWA99TuSN_qDHyxyWV6RdRQKvkC2Pu5--PFfu1QzEGl_Lfl-tBJ7jsUyeTE4SoUrmjW76xT_7XCURSmBM4KEy_ew2zghdrjwfNUDUpKpDr7aY2V6ptcoJFDZqSQNLf2SdtAD0R-vNOmlNmPm5AdMrHNAIPUuT3c2nqOw3wWv9p2i9cQ5bQIzxjeCncGl1v29ZSnyMqM3yExeXixGl9nDepQiOOish3PZ",
}

SATIRE_DESK = Author(
    id="satire_desk",
    name="Banana Satire Desk",
    title="Department of Totally Real News",
    bio="A rotating cast of interns, one confused parrot, and an AI that was told to "
        "'write something newsy'. Nothing they publish has ever happened.",
    avatar_s3_key="https://assets.banana.in/wp-content/uploads/2018/01/banana_favicon.png",
)

# (id, category, title, excerpt, body, image, author, read_min, hours_ago, premium, locked, tags)
MOCK_ARTICLES = [
    (
        "mock-2026-001", "POLITICS",
        "[MOCK] Parliament session adjourned after MPs discover the Wi-Fi password is 'password'",
        "Opposition demands a Joint Parliamentary Committee to investigate who chose it; ruling side says it was 'Password@123' all along.",
        "Proceedings in the Lok Sabha were adjourned for the 47th consecutive time this week after a backbencher, attempting to stream a cricket match, "
        "accidentally announced the house Wi-Fi password over the public address system.\n\n"
        "The password, sources confirmed, was 'password'. A follow-up probe found that the backup network was named 'Definitely Not The Speaker' and had no password at all.\n\n"
        "The Ministry of Digital Affairs (Fictional Division) issued a statement clarifying that the password is 'rotated every five years, in line with the electoral cycle'.",
        "politics", "satire_desk", 3, 1, False, False, ["Elections", "Satire"],
    ),
    (
        "mock-2026-002", "POLITICS",
        "[MOCK] Candidate promises free Wi-Fi, free laddoos and a 'free-er' freedom in 7-hour manifesto launch",
        "Manifesto runs 1,412 pages; page 900 is just the word 'jalebi' repeated.",
        "Unveiling what aides called 'the most ambitious document since the telephone directory', the candidate of the newly formed Ultra Progressive Regressive Party "
        "promised every citizen free Wi-Fi, two laddoos a day, and 'a freedom that is somehow more free than the existing freedom'.\n\n"
        "When asked how this would be funded, the candidate pointed at the sky for eleven seconds and then left in a helicopter.\n\n"
        "Political analysts described the move as 'bold', 'confusing', and 'mostly jalebi'.",
        "politics", "satire_desk", 4, 3, False, False, ["Elections", "Satire"],
    ),
    (
        "mock-2026-003", "Economy",
        "[MOCK] Sensex crashes 900 points after trader sneezes on 'Sell All' button",
        "Markets recover by lunch once everyone agrees to pretend it didn't happen.",
        "Dalal Street saw a brief moment of panic on Tuesday morning when a junior trader, battling a seasonal cold, sneezed directly onto a keyboard "
        "configured with a single giant 'SELL ALL' key.\n\n"
        "Within four minutes the index had shed 900 points, three economists had appeared on television to blame global headwinds, and one had blamed Mercury.\n\n"
        "By 1 p.m. the market had recovered fully after the exchange issued a circular titled 'Bless You', which analysts are calling the most effective monetary signal of the year.",
        "economy", "vikram_sethi", 4, 2, False, False, ["Economy", "Satire"],
    ),
    (
        "mock-2026-004", "Economy",
        "[MOCK] RBI introduces ₹7 coin 'because why not', public asked to stop asking questions",
        "Governor says odd denominations will 'keep citizens mentally agile'.",
        "In a surprise announcement, the Reserve Bank of Imaginary India unveiled a brand-new ₹7 coin, shaped like a heptagon and featuring an embossed banana on the reverse.\n\n"
        "'We had a meeting, someone said seven, and nobody objected,' an official said on the condition of anonymity, and also of reality.\n\n"
        "Shopkeepers nationwide have responded by pricing every item at ₹7, ₹14, or 'please just use UPI'.",
        "economy", "satire_desk", 3, 9, False, False, ["Economy", "Satire"],
    ),
    (
        "mock-2026-005", "Tech",
        "[MOCK] Bengaluru startup raises $40M to build an app that reminds you to close other apps",
        "Founder: 'We are not an app. We are an anti-app app. Also please download the app.'",
        "AppClose AI, a Koramangala-based startup with 3 employees and 47 advisors, has raised a $40 million Series A to solve what it calls 'the app crisis'.\n\n"
        "The product sends a push notification every 90 seconds reminding users to close any app that is sending them push notifications, including itself.\n\n"
        "Investors praised the company's 'recursive go-to-market strategy'. The app is currently ranked #1 in the category of 'apps uninstalled within one minute'.",
        "tech", "zane_malik", 5, 5, False, False, ["Tech", "Startups", "Satire"],
    ),
    (
        "mock-2026-006", "Tech",
        "[MOCK] AI chatbot elected housing society secretary, immediately bans all WhatsApp good-morning forwards",
        "Residents divided: half call it tyranny, the other half have finally slept in peace.",
        "In a historic first for Residents' Welfare Associations, an AI chatbot named 'SocietyGPT' won the secretary's election at Green Meadows Phase 4 by a landslide margin of 212 votes to 3.\n\n"
        "Its first act in office was banning 'Good Morning' images featuring roses, sunrises, or glittering teacups from the society WhatsApp group.\n\n"
        "Uncle Sharma from B-Wing has filed a petition, written entirely in sunflower GIFs.",
        "tech", "satire_desk", 3, 7, False, False, ["Tech", "Satire"],
    ),
    (
        "mock-2026-007", "Science",
        "[MOCK] Scientists confirm traffic on Silk Board junction is now visible from Mars",
        "Mars rover reportedly honked back.",
        "Astronomers at the entirely made-up Indian Institute of Space Gossip have confirmed that the evening traffic jam at Silk Board junction is now visible from the surface of Mars.\n\n"
        "Images transmitted by a Martian rover show a faint orange smudge of brake lights stretching across south Bengaluru. The rover then attempted a U-turn and has not been heard from since.\n\n"
        "Commuters were unsurprised. 'I've been in this auto since the mission launched,' one said.",
        "science", "satire_desk", 3, 4, False, False, ["ISRO", "Satire"],
    ),
    (
        "mock-2026-008", "Science",
        "[MOCK] Breakthrough study finds chai consumption directly proportional to number of meetings",
        "Researchers needed 14,000 cups to reach statistical significance.",
        "A two-year study by the National Bureau of Obvious Findings has proven that office chai consumption rises linearly with the number of meetings scheduled per day.\n\n"
        "'Every meeting that could have been an email adds 1.3 cups,' said the lead researcher, who was interviewed between two meetings and holding three cups.\n\n"
        "The paper has been submitted to a peer-reviewed journal. The reviewers have requested a meeting.",
        "science", "satire_desk", 4, 20, False, False, ["Satire"],
    ),
    (
        "mock-2026-009", "Environment",
        "[MOCK] Delhi's air quality so bad that air purifiers have started filing for leave",
        "One purifier reportedly applied for a transfer to Shimla.",
        "Delhi's AQI crossed 'please don't' on Monday, prompting the city's household air purifiers to collectively submit leave applications citing 'emotional exhaustion'.\n\n"
        "A spokesperson for the Federation of Filters said its members had been working overtime since Diwali and deserved 'at least one breath of fresh air'.\n\n"
        "The government has responded by declaring the smog 'a natural Instagram filter' and recommending citizens breathe 'less, but better'.",
        "environment", "sanjay_kapoor", 4, 6, False, False, ["Satire"],
    ),
    (
        "mock-2026-010", "Environment",
        "[MOCK] Monsoon officially files RTI asking why every city still floods after 'one drizzle'",
        "Municipal corporation says reply will be sent 'after the next monsoon'.",
        "In an unprecedented move, the South-West Monsoon has filed a Right to Information application with seven municipal corporations, asking why "
        "storm drains are still blocked despite budget allocations being approved 'every single year since 1987'.\n\n"
        "Officials have requested 30 days to respond, and an additional 30 years to clean the drains.",
        "environment", "satire_desk", 3, 30, False, False, ["Satire"],
    ),
    (
        "mock-2026-011", "Diplomacy",
        "[MOCK] Summit breakthrough: world leaders agree samosa is a sandwich, refuse to discuss further",
        "Joint communiqué runs to one line; translators exhausted anyway.",
        "After three days of closed-door negotiations at the Global Snack Summit, delegates from 41 fictional nations signed the historic Samosa Accord, "
        "formally classifying the samosa as 'a triangular sandwich of destiny'.\n\n"
        "The accord's only other clause prohibits any future discussion of whether a hot dog is a sandwich, citing 'irreconcilable trauma'.\n\n"
        "Markets responded positively. Chutney futures are up 12%.",
        "diplomacy", "meera_nair", 5, 11, False, False, ["Diplomacy", "Satire"],
    ),
    (
        "mock-2026-012", "Investigation",
        "[MOCK] FinePrint exposé: the pothole on MG Road has been promoted to junior engineer",
        "Six-month investigation finds the pothole has outlasted four contractors and two governments.",
        "A painstaking FinePrint investigation has revealed that the iconic pothole outside 14 MG Road, first reported in 2011, has been quietly added to the "
        "municipal payroll as a Junior Engineer (Grade II).\n\n"
        "Documents obtained by Banana Ganrajya show the pothole has received three performance bonuses, a laptop, and a farewell party for a contractor who tried to fill it.\n\n"
        "When approached for comment, the pothole swallowed our reporter's scooter. We consider that a 'no comment'.",
        "investigation", "satire_desk", 9, 14, True, False, ["Investigation", "Satire"],
    ),
    (
        "mock-2026-013", "Investigation",
        "[MOCK] Leaked files reveal pigeons have been running the Ministry of Statistics since 2019",
        "Premium dossier: How 'coo' became the official unit of measurement.",
        "In what is already being called Pigeongate, leaked internal files suggest that a committee of pigeons nesting above the Ministry of Statistics (Imaginary) "
        "has been signing off on national data releases for over seven years.\n\n"
        "Analysts first grew suspicious when the GDP growth figure was reported as 'coo coo point five'. Further digging revealed that all quarterly reports had been "
        "printed on breadcrumbs.\n\n"
        "The ministry has denied the report, in a statement that was later found to be mostly feathers.",
        "investigation", "satire_desk", 11, 26, True, True, ["Investigation", "Satire"],
    ),
    (
        "mock-2026-014", "Opinion",
        "[MOCK] Opinion: It is time we admitted the office AC has a political agenda",
        "Set to 16°C in summer and 30°C in winter, it has never once served the people.",
        "I have spent eleven years at the same desk under the same air conditioner, and I am now ready to say what we have all been thinking: the AC is not neutral.\n\n"
        "It freezes the junior staff, spares the corner office, and goes mysteriously silent whenever facilities management walks by. That is not a malfunction. That is a platform.\n\n"
        "We must demand transparency. We must demand a remote. Most of all, we must demand to know who keeps setting it to 'Turbo'.",
        "opinion", "aruna_singh", 6, 8, False, False, ["Satire"],
    ),
    (
        "mock-2026-015", "Opinion",
        "[MOCK] Opinion: My uncle's WhatsApp forwards should be peer-reviewed",
        "If he can cite NASA, NASA should be allowed to reply.",
        "Every morning at 6:02 a.m., my uncle publishes groundbreaking research to the family group. Last week he proved, via a blurry JPEG, that onions cure Wi-Fi lag.\n\n"
        "I propose a modest reform: every forward must be reviewed by two independent aunties before publication, and any claim mentioning NASA must include NASA's phone number.\n\n"
        "Until then, I will continue responding with the thumbs-up emoji, the most powerful act of non-violent resistance available to the modern nephew.",
        "opinion", "vikram_sethi", 5, 18, False, False, ["Satire"],
    ),
]


def _time_ago(hours: int) -> str:
    if hours < 1:
        return "Just Now"
    if hours < 24:
        return f"{hours}h ago"
    if hours < 48:
        return "Yesterday"
    return f"{hours // 24} days ago"


def seed_mock_news() -> None:
    db: Session = SessionLocal()
    try:
        db.merge(SATIRE_DESK)
        db.flush()

        tag_cache: dict[str, Tag] = {}

        def get_tag(name: str) -> Tag:
            if name not in tag_cache:
                tag = db.query(Tag).filter(Tag.name == name).first()
                if tag is None:
                    tag = Tag(name=name)
                    db.add(tag)
                    db.flush()
                tag_cache[name] = tag
            return tag_cache[name]

        now = datetime.utcnow()
        created = 0
        for (aid, cat, title, excerpt, body, img, author_id, mins, hrs, prem, locked, tags) in MOCK_ARTICLES:
            if db.get(Author, author_id) is None:
                author_id = SATIRE_DESK.id  # base seed missing -> fall back
            art = db.get(Article, aid)
            if art is None:
                art = Article(id=aid)
                db.add(art)
                created += 1
            art.category = cat
            art.title = title
            art.excerpt = excerpt
            art.body = body + DISCLAIMER
            art.cover_image_s3_key = IMG[img]
            art.author_id = author_id
            art.read_time_minutes = mins
            art.time_ago = _time_ago(hrs)
            art.is_premium = prem
            art.is_locked = locked
            art.published_at = now - timedelta(hours=hrs)
            art.tags = [get_tag(t) for t in tags]

        db.commit()
        print(f"Mock news seeded: {created} new, {len(MOCK_ARTICLES) - created} updated.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_mock_news()
