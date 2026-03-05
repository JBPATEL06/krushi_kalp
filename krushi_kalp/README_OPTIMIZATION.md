# MockTest App Optimization & Architecture Documentation

This document outlines the standard architecture, state management, and database schema used in the **Optimized** version of the application.

## 1. Architecture: MVVM (Model-View-ViewModel)

We follow the **MVVM** pattern to ensure separation of concerns, testability, and scalability.

-   **Model (`lib/domain/models`)**:
    -   Pure Dart classes representing data objects (e.g., `MockTest`, `User`).
    -   Should **not** contain any logic or Flutter dependencies.

-   **View (`lib/presentation/screens`)**:
    -   The UI layer (Widgets).
    -   **"Dumb" Widgets**: Views should only display data given to them.
    -   They listen to `Providers` for changes and rebuild accordingly.
    -   **No business logic** inside UI files (except simple navigation).

-   **ViewModel / Provider (`lib/presentation/providers`)**:
    -   Holds the state for the Views.
    -   Communicates with Repositories to fetch data.
    -   Exposes data to Views via `Consumer` or `context.watch`.
    -   **State Management**: We use the `provider` package.

-   **Repository (`lib/data/repositories`)**:
    -   Handling data fetching (Supabase, API, Local Storage).
    -   Implements **Caching** (e.g., in-memory cache) to reduce internet usage.

## 2. State Management

We use **Provider** for state management because it is:
-   **Lightweight**: Minimal boilerplate.
-   **Efficient**: Rebuilds only what changed.
-   **Standard**: Recommended by the Flutter team.

### Core Providers:
1.  **`AuthProvider`**: Manages User Session, Login, Logout, and Role (Admin/Student).
2.  **`TestProvider`**: Manages Mock Tests, filtering, and "Active" test state.
    -   *Cache Policy*: Fetches tests once and stores in memory. Refreshed only on explicit user action (Pull-to-Refresh).
3.  **`AdminProvider`**: Manages Dashboard stats and User lists for Admins.

## 3. Database Schema

We use **Supabase (PostgreSQL)**.

### Optimizations for Reducing Tables:
-   **Questions**: Stored as **JSON Files** in Supabase Storage (Bucket: `mock_test`).
    -   *Why?* Drastically reduces table row count (1 file vs 100 rows per test).
    -   *perf*: Faster to load one file than query 100 rows.

### Core Tables:
1.  **`users`**: Extended profile data (linked to `auth.users`).
    -   `id` (UUID), `email`, `role` (Admin/Student), `created_at`.
2.  **`mock_tests`**: Metadata for tests.
    -   `test_id`, `title`, `price`, `file_path` (link to JSON), `cover_image_path`.
3.  **`results`**: History of attempts.
    -   `result_id`, `user_id`, `test_id`, `score`, `attempt_date`.
4.  **`orders`**: Purchase history.
    -   `item_id`, `user_id`, `test_id`, `payment_id` (not null = paid).

## 4. Internet Consumption Optimization

To ensure the app is "Lightweight" and saves data:
1.  **Image Caching**: All network images usage `CachedNetworkImage`. Images are downloaded once and saved locally.
2.  **Data Caching**: Providers store fetched lists. Switching tabs does **not** trigger a new API call.
3.  **Selective Query**: We calculate stats (like "Sales Count") on the server or using `count` queries rather than downloading full datasets.

## 5. Development Guidelines
-   **Always** use `const` constructors for UI widgets where possible.
-   **Never** call `setState` for global data (use Provider).
-   **Always** handle Errors gracefully (show Snackbars, not crashes).
-   **Delete Logic**: deleting a Test calculates cascading deletes (Results, Orders, Files) automatically.
