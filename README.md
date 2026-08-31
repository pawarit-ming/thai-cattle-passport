# Thai Cattle Passport

A Flutter app that gives every head of cattle a verifiable identity and a health
record that follows it to its next owner. Cattle in Thailand change hands often
and the animal's history — vaccinations, treatments, previous owners — tends not
to travel with it; a buyer takes the seller's word for it because there is no
record to check.

Built by three of us as our senior project at Mahidol University,
September 2025 – May 2026.

📝 [Case study with screenshots →](https://pawarit-wang.vercel.app/projects/thai-cattle-passport)

---

## Whose work is what

**This is a team project**, republished here as a portfolio reference. Most of the
herd, cow-form, activity-logging and notification code is my teammates' work, and
it is here because the app does not make sense in pieces.

What I built:

| Area | Files |
| --- | --- |
| **Marketplace** — listings, search and filtering, seller and farm details, offer tracking, and the ownership-transfer flow including foster arrangements | `lib/ui/screens/buy_screen.dart` (975 lines mine) · `lib/ui/screens/offer_screen.dart` (438) |
| **Password recovery** with deep links back into the app | `lib/ui/screens/auth/forgot_password_screen.dart` · `auth/update_password_screen.dart` |
| **QR passport scanner** — opens an animal's public read-only profile from a scan | `lib/ui/screens/qr_scanner_screen.dart` |
| **Routing** — including the public passport route registered against the root navigator, so a scan lands on a clean profile instead of dropping a stranger into the owner's navigation | `lib/routes/app_router.dart` |
| **Camera capture** for an animal's reference photos | `lib/ui/widgets/camera_widget.dart` |

I also worked on the identification model with the team — a ConvNeXt-Tiny metric
learner that decides whether two photos show the same animal, averaging 94.6%
accuracy and AUC above 0.94 across five folds. That model is not in this
repository; the app calls it over REST.

`git blame` on any file shows the split honestly.

## Configuring Supabase

The credentials in `lib/supabase_config.dart` are placeholders — the project's own
Supabase keys were removed from the entire commit history before publishing. To
run this against a backend you need your own Supabase project:

```dart
// lib/supabase_config.dart
static const String url = 'https://YOUR_PROJECT.supabase.co';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
static const String bucketName = 'cow';
```

The schema it expects is visible from the service layer in `lib/services/` —
`auth`, `cow_management`, `farm`, `offer`, `profile` and `notification` — plus a
storage bucket for photos. Row-level security scopes a farm's data to its owner while
leaving the public passport view readable by anyone holding the QR link.

```bash
flutter pub get
flutter run
```

## Stack

Flutter · Dart · Riverpod (state) · go_router (navigation) · Supabase (auth,
Postgres, storage) · Google Maps · `qr_flutter` and `mobile_scanner` to write and read the
passport codes · `camera` and `image_picker` for the reference photos.

## Team

Three of us over the final year of the degree. We worked on the identification
model together and split the application between us.

---

Archived — the state of the project at submission in May 2026, kept as a
portfolio reference rather than a maintained app.
