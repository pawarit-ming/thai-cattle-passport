# TH Cow Passport

A Flutter application for managing cow passports.

## Features

- Add new cows with details and images.
- View a list of all cows.
- Delete cows from the list.
- (In Progress) Edit existing cow details.

## Architecture

This project uses a layered architecture inspired by Clean Architecture and MVVM.

- **`lib/services`**: Contains the business logic and data access layers.
  - **`lib/services/cow`**: Handles all cow-related business logic.
    - **`cow_service.dart`**: A service class that interacts with the Supabase backend to perform CRUD operations on cows.
    - **`models/cow_model.dart`**: The data model for a cow.
- **`lib/ui`**: Contains the presentation layer (UI).
  - **`lib/ui/screens`**: The different screens of the application.
    - **`cow_list_screen.dart`**: Displays the list of cows.
    - **`cow_form_screen.dart`**: A form to add or edit a cow.
  - **`lib/ui/widgets`**: Reusable widgets.
- **`lib/routes`**: Defines the application's routes using `go_router`.
- **`lib/main.dart`**: The entry point of the application.
- **`lib/supabase_config.dart`**: Configuration for the Supabase client.

## Getting Started

### Prerequisites

- Flutter SDK
- A Supabase project with a table named `animals` that matches the `Cow` model.
- A Supabase storage bucket.

### Installation

1. Clone the repository.
2. Create a `lib/supabase_config.dart` file with your Supabase credentials:
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';

   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     static const String bucketName = 'YOUR_BUCKET_NAME';
   }

   final supabase = Supabase.instance.client;
   ```
3. Run `flutter pub get` to install the dependencies.
4. Run the application: `flutter run`.

## Dependencies

- `flutter_riverpod`: For state management.
- `go_router`: For navigation.
- `supabase_flutter`: For interacting with the Supabase backend.
- `image_picker`: For picking images from the gallery or camera.
