#!/bin/bash

# Script to add logger imports and replace all print statements with logger calls

echo "🔧 Starting logger fix script..."

# Find all dart files that contain print statements
echo "📋 Finding files with print statements..."
print_files=$(grep -r "print(" lib/ --include="*.dart" | cut -d: -f1 | sort -u)

if [ -z "$print_files" ]; then
    echo "✅ No print statements found!"
    exit 0
fi

echo "📁 Found print statements in these files:"
echo "$print_files"

# Process each file
for file in $print_files; do
    echo "🔄 Processing: $file"
    
    # Check if logger import already exists
    if ! grep -q "import.*logger_service" "$file"; then
        echo "  📥 Adding logger import to $file"
        
        # Find the last import line and add logger import after it
        sed -i "/^import /a import '../services/logger_service.dart';" "$file" 2>/dev/null || \
        sed -i "/^import /a import 'logger_service.dart';" "$file" 2>/dev/null || \
        sed -i "1i import '../services/logger_service.dart';" "$file"
    else
        echo "  ✅ Logger import already exists in $file"
    fi
    
    # Replace print statements with logger calls using comprehensive regex
    echo "  🔄 Replacing print statements in $file"
    
    # Replace basic print( with logger.debug(
    sed -i 's/print(/logger.debug(/g' "$file"
    
    # Handle multi-line print statements
    sed -i ':a;N;$!ba;s/logger\.debug(\n/logger.debug(/g' "$file"
    
    echo "  ✅ Completed: $file"
done

echo ""
echo "🔧 Fixing specific logger import paths..."

# Fix import paths for files in different directories
find lib/ -name "*.dart" -exec sed -i "s|import '../services/logger_service.dart';|import 'logger_service.dart';|g" {} \; 2>/dev/null
find lib/services/ -name "*.dart" -exec sed -i "s|import '../services/logger_service.dart';|import 'logger_service.dart';|g" {} \; 2>/dev/null
find lib/providers/ -name "*.dart" -exec sed -i "s|import '../services/logger_service.dart';|import '../services/logger_service.dart';|g" {} \; 2>/dev/null
find lib/screens/ -name "*.dart" -exec sed -i "s|import 'logger_service.dart';|import '../../services/logger_service.dart';|g" {} \; 2>/dev/null
find lib/screens/home/ -name "*.dart" -exec sed -i "s|import 'logger_service.dart';|import '../../../services/logger_service.dart';|g" {} \; 2>/dev/null
find lib/screens/home/widgets/ -name "*.dart" -exec sed -i "s|import 'logger_service.dart';|import '../../../../services/logger_service.dart';|g" {} \; 2>/dev/null
find lib/features/ -name "*.dart" -exec sed -i "s|import 'logger_service.dart';|import '../../../services/logger_service.dart';|g" {} \; 2>/dev/null
find lib/widgets/ -name "*.dart" -exec sed -i "s|import 'logger_service.dart';|import '../services/logger_service.dart';|g" {} \; 2>/dev/null

echo ""
echo "🧹 Cleaning up duplicate imports..."

# Remove duplicate logger imports
find lib/ -name "*.dart" -exec sed -i '/import.*logger_service/d' {} \;

# Add single logger import to each file that uses logger
for file in $(grep -l "logger\." lib/**/*.dart 2>/dev/null); do
    # Determine correct import path based on file location
    if [[ "$file" == lib/services/* ]]; then
        import_path="import 'logger_service.dart';"
    elif [[ "$file" == lib/providers/* ]]; then
        import_path="import '../services/logger_service.dart';"
    elif [[ "$file" == lib/screens/home/widgets/* ]]; then
        import_path="import '../../../../services/logger_service.dart';"
    elif [[ "$file" == lib/screens/home/* ]]; then
        import_path="import '../../../services/logger_service.dart';"
    elif [[ "$file" == lib/screens/* ]]; then
        import_path="import '../../services/logger_service.dart';"
    elif [[ "$file" == lib/features/*/* ]]; then
        import_path="import '../../../services/logger_service.dart';"
    elif [[ "$file" == lib/widgets/* ]]; then
        import_path="import '../services/logger_service.dart';"
    else
        import_path="import 'services/logger_service.dart';"
    fi
    
    # Add import after the last existing import
    if grep -q "^import " "$file"; then
        sed -i "/^import /a\\
$import_path" "$file"
    else
        sed -i "1i\\
$import_path" "$file"
    fi
done

echo ""
echo "🎯 Optimizing logger calls..."

# Replace different types of print statements with appropriate logger levels
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("❌/logger.error("❌/g' {} \;
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("⚠️/logger.warning("⚠️/g' {} \;
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("🔐/logger.auth("🔐/g' {} \;
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("🌐/logger.api("🌐/g' {} \;
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("🔥/logger.firebase("🔥/g' {} \;
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("👤/logger.userAction("👤/g' {} \;
find lib/ -name "*.dart" -exec sed -i 's/logger\.debug("📍/logger.navigation("📍/g' {} \;

echo ""
echo "✅ Logger fix completed!"
echo ""
echo "📊 Summary:"
echo "  - Files processed: $(echo "$print_files" | wc -l)"
echo "  - Files with logger calls: $(grep -l "logger\." lib/**/*.dart 2>/dev/null | wc -l)"
echo ""
echo "🧪 Running flutter analyze to check for issues..."
