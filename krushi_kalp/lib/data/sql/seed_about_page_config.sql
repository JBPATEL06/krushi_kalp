-- Migration: seed_about_page_config.sql
INSERT INTO public.app_config (key, value, description)
VALUES (
  'about_page',
  '{
    "app_name": "Krushi Kalp",
    "version": "2.4.0",
    "tagline": "EMPOWERING AGRICULTURE STUDENTS",
    "mission": "Krushi Kalp is dedicated to bridging the gap between academic learning and professional excellence for agricultural students. We provide a comprehensive digital ecosystem for mastering core concepts through curated resources, rigorous testing, and data-driven insights.",
    "features": [
      {"icon": "quiz", "title": "Adaptive Mock Tests", "subtitle": "Personalized exam simulations"},
      {"icon": "menu_book", "title": "Study Materials", "subtitle": "Curated agricultural curriculum"},
      {"icon": "bar_chart", "title": "Real-time Analytics", "subtitle": "Track your progress and rankings"}
    ],
    "support": {
      "email": "support@krushikalp.com",
      "address": "Agricultural University Hub, Delhi",
      "support_label": "Need Support?",
      "support_description": "Our academic advisors are here to help you excel."
    },
    "footer_text": "MADE WITH EXCELLENCE FOR INDIA''S FUTURE FARMERS"
  }'::jsonb,
  'About page content — editable by admin from Manage App > About Page tab'
)
ON CONFLICT (key) DO NOTHING;
