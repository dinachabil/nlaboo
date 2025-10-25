# Quick Command Reference

## 🚀 Deploy Commands

### Apply All Fixes (Copy & Paste)
```bash
# Navigate to project
cd d:\Projets\Dev\footconnect\footconnect\nlaabo

# Apply database migrations
supabase db push

# Clean and rebuild
flutter clean
flutter pub get

# Run in profile mode
flutter run --profile
```

---

## 🔧 Individual Commands

### Database
```bash
# Apply migrations
supabase db push

# Reset database (careful!)
supabase db reset

# View migration status
supabase migration list
```

### Flutter
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run debug
flutter run

# Run profile (for performance testing)
flutter run --profile

# Run release
flutter run --release

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

### Performance
```bash
# Profile performance
flutter run --profile --trace-startup

# Analyze bundle size
flutter build apk --analyze-size

# Check memory leaks
flutter run --profile --trace-skia
```

---

## 🐛 Troubleshooting Commands

### If Build Fails
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### If Migration Fails
```bash
# Check Supabase status
supabase status

# View logs
supabase db logs

# Manually apply SQL
# Go to Supabase Dashboard > SQL Editor
# Run migration files manually
```

### If App Crashes
```bash
# Clear app data
flutter clean

# Reinstall
flutter run --uninstall-first
```

---

## 📊 Monitoring Commands

### Check Performance
```bash
# Enable performance overlay
flutter run --profile

# Check frame rendering
flutter run --trace-skia

# Memory profiling
flutter run --profile --trace-startup
```

### View Logs
```bash
# Flutter logs
flutter logs

# Supabase logs
supabase db logs

# Clear logs
flutter clean
```

---

## ✅ Verification Commands

### After Deployment
```bash
# Verify build
flutter doctor -v

# Check dependencies
flutter pub deps

# Analyze code quality
flutter analyze

# Run tests
flutter test
```

---

## 🎯 One-Line Deploy

```bash
cd d:\Projets\Dev\footconnect\footconnect\nlaabo && supabase db push && flutter clean && flutter pub get && flutter run --profile
```

Copy and paste this single command to deploy everything! 🚀
