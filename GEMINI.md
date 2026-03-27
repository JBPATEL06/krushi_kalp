# Industry-Standard Development Rules

## 🏗 Architecture & Logic
1. **Separation of Concerns:** Business logic must reside in Providers/Notifiers. UI widgets must be as "dumb" as possible.
2. **Logic Integrity:** During UI refactors, protect existing State Management and Data Models. Never alter business logic unless explicitly requested.
3. **Type Safety:** All API responses must be mapped to strongly-typed Data Models. No dynamic types allowed in production code.

## 📱 Responsive & UI Standards
1. **Simultaneous Compatibility:** Every screen MUST be responsive for Mobile, Tablet, and Web using `ResponsiveBreakpoints`.
2. **Standard Breakpoints:** - Mobile: 0 - 450
   - Tablet: 451 - 800
   - Desktop/Web: 801+
3. **Asset Optimization:** Use `CachedNetworkImage` with custom `Shimmer` loaders for all network resources.

## 🚀 Performance & Security
1. **Frame Stability:** Wrap high-frequency list items and complex animations in `RepaintBoundary`.
2. **Immutability:** Use `const` constructors where possible and `final` for non-changing variables.
3. **Secrets Management:** Use `Envied` for all API keys and environment variables. Never hardcode sensitive strings.