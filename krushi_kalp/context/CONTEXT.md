# Krushi Kalp App Context

## Project Overview
Krushi Kalp is a Flutter-based educational/agricultural application providing mock tests, resources (ebooks, PYQs, GK), and banners.

## Tech Stack
- Frontend: Flutter, Riverpod, GoRouter
- Backend: Supabase (Auth, Storage, Database)
- PDF: PDF package for report generation

## Current Stabilization Phase
- Goal: Fix critical bugs in Admin panel, PDF generation, and UX.
- Admin Panel: RLS policies and form submission fixes.
- User Part: PDF generation (testId/fonts), PYQ filters, Cart logic.

## Key Decisions
- Use background uploading ('Fire and Forget') for admin forms.
- Dynamic font loading in PdfService based on language code.
- RLS policy standardization for 'authenticated' role.

## Known Risks
- Guest user bypass for PDF uploads (Pending).
- Cart navigation side-effects (Investigating).
