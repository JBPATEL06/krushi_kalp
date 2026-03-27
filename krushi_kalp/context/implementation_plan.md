# 🚀 Krushi Kalp - System Upgrade Plan (Hinglish)

Yeh document Krushi Kalp app ke do sabse bade issues ko solve karne ka step-by-step plan hai: Database ka bill kam karna aur Payment (Razorpay) ki security badhana.

---

## 🟢 Part 1: Optimization (Isar & Notifications)

**Aapki Requirement:** Notifications (WebSockets) ko nahi hatana hai kyunki wo app ke liye zaruri hain.
**Plan:**
1. **Notifications Safe:** Hum `.channel()` subscriptions ko touch nahi karenge taki aapki push notifications and updates exactly wese hi kaam karein jaise abhi kar rahi hain.
2. **Isar NoSQL (Local Cache):** Magar lists (jaise mock tests ya store items) ko har baar Supabase se download karne ke bajaye hum unhe **Isar Database** mein save kar lenge. Isse bina WebSockets hataye aapka 80-90% data bill kam ho jayega kyu ki image/text load hone ka cost bach jayega!

---

## 🔒 Part 2: Secure Server-Side Pricing (Pure SQL)

**Aapki Requirement:** Apna UI "Fake / Real Offers" logic kharab nahi hona chahiye (pol nahi khulni chahiye) aur Type-Script/Edge Functions use MAAT karo, sirf **SQL** use karo.
**Plan:**
1. **Supabase SQL RPC Function (`calculate_secure_price`):**
    - Hum Supabase ke andar ek pure **PostgreSQL Function** banayenge (SQL Editor ke through). Koi node.js ya external server nahi chahiye!
    - Jab user app mein checkout par click karega, Flutter app is SQL function ko "Test ID" aur "Coupon Code" bhejayga.
    - SQL function exactly aapka existing offer logic (fake vs real discount) apply karke final secure price return karega.
2. **Flutter App Integration:**
    - Flutter app bina kisi khud ke calculation ke, seedha SQL se aaya hua price uthayega aur Razorpay open kar dega.
    - Isse app bilkul secure ban jayega aur aapka marketing UI ("Fake strike-through prices") bhi perfect 100% same chalega.

**Next Step:** Main abhi aapko wo **SQL Query** bana kar deta hoon jo aap seedha apne Supabase ke SQL Editor mein copy-paste karke run kar sakte hain. Jab bolenge tab main code mein changes start karunga!
