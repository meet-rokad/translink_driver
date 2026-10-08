# 🚚 Return Translink - Project Roadmap & Bug Tracker

This document tracks pending features, known bugs/architectural issues, and future enhancements for the Return Translink mobile application.

## 🔴 High Priority / Bugs (Immediate Action Required)

- [x] **Auth Architecture Sync**: Currently using Firebase for OTP/Login and Supabase for the database. This dual setup is prone to token mismatch and security risks. 
      **Fix:** Migrate OTP and Login entirely to Supabase Auth. (Completed)
- [ ] **Return Trip Flow (UI/UX)**: Change the toggle in the "Add Return Trip" screen to a YES/NO button format.
      - If **YES**: Create the return trip.
      - If **NO**: Prompt the user to update their current location.

## 🟡 Medium Priority (Core Features Missing)

- [ ] **Google Maps Integration**: 
      - Replace manual text inputs for locations (e.g., "Surat") with Google Places Autocomplete.
      - Draw poly-lines on the map showing origin and destination.
      - Use exact Latitude/Longitude for distance calculations.
- [ ] **Background Location Tracking**: 
      - The app must fetch and push the driver's location to Supabase every 20-30 minutes even when the app is killed or running in the background. This is crucial for matching return loads.
- [ ] **Push Notifications**: 
      - Integrate Firebase Cloud Messaging (FCM) or OneSignal.
      - Alert drivers instantly when a load matches their return route.

## 🟢 Low Priority / Future Enhancements (To Make the App Premium)

- [ ] **OCR for Document Verification**: 
      - Implement Google Cloud Vision or a dedicated Indian KYC API to auto-scan Aadhaar, DL, RC, PUC, and Insurance.
      - Auto-fill details from the cards to prevent fake uploads and reduce manual backend review time.
- [ ] **Fare Estimation Engine**: 
      - Calculate approximate fuel cost, toll taxes (using TollGuru API or similar), and base rate to suggest a fair return trip price.
- [ ] **In-App Chat / Call Masking**: 
      - Allow drivers and shippers to chat within the app.
      - Mask phone numbers during calls (using Twilio/Exotel) to maintain privacy and keep transactions on the platform.
- [ ] **Wallet / Payment Gateway**: 
      - Integrate Razorpay or Cashfree.
      - Allow shippers to pay a token advance directly through the app to confirm the booking.
- [ ] **Driver Analytics / Earning Dashboard**: 
      - Show graphs of monthly earnings, total distance traveled, and fuel efficiency insights based on app data.

---
*Note: Keep updating this file as new ideas or bugs are discovered during development.*
