# Cactus Dashboard - Flutter Web Application

لوحة تحكم مالية لإدارة عمليات التحويلات المالية للتجار والماكينات الإلكترونية.

A financial dashboard web application for managing financial transactions for merchants and electronic payment terminals.

## المميزات / Features

### للمدير / Admin
- ✅ عرض جميع التجار
- ✅ البحث عن التاجر (بالاسم، الرقم، أو الكود)
- ✅ تصدير بيانات التجار إلى CSV

### للتاجر / Merchant
- ✅ عرض جميع التحويلات المالية (نجحت، مرفوضة، معلقة)
- ✅ فلترة التحويلات حسب الماكينة
- ✅ فلترة التحويلات حسب التاريخ (نطاق تاريخي)
- ✅ فلترة التحويلات حسب الحالة
- ✅ البحث في التحويلات
- ✅ تصدير التحويلات إلى CSV
- ✅ عرض إحصائيات مالية تفصيلية
- ✅ مخططات بيانية (خطي ودائري) للحركة المالية
- ✅ إحصائيات أسبوعية، شهرية، وسنوية

### عام / General
- ✅ دعم اللغة العربية والإنجليزية
- ✅ تصميم متجاوب (Desktop & Mobile)
- ✅ واجهة مستخدم حديثة وأنيقة
- ✅ أنيميشن سلس للصفحات والعناصر
- ✅ تصميم بدون ظلال مع حواف دائرية

## التقنيات المستخدمة / Technologies

- **Flutter Web** - إطار العمل الرئيسي
- **Provider** - إدارة الحالة
- **fl_chart** - المخططات البيانية
- **intl** - التنسيق والتوطين
- **csv** - تصدير البيانات

## المتطلبات / Requirements

- Flutter SDK (3.0.0 أو أحدث)
- Dart SDK (3.0.0 أو أحدث)
- متصفح ويب حديث

## التثبيت والتشغيل / Installation & Run

### 1. استنساخ المشروع / Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/cactus_dashboard_flutter_web.git
cd cactus_dashboard_flutter_web
```

### 2. تثبيت التبعيات / Install dependencies
```bash
flutter pub get
```

### 3. تشغيل التطبيق / Run the application
```bash
flutter run -d chrome
```

أو للويب:
```bash
flutter run -d web-server --web-port=8080
```

### 4. بناء التطبيق للإنتاج / Build for production
```bash
flutter build web
```

## بيانات الاختبار / Test Data

التطبيق يستخدم بيانات اختبارية من ملف `assets/data/test_data.json`.

### بيانات تسجيل الدخول / Login Credentials

**مدير / Admin:**
- اسم المستخدم: `admin`
- كلمة المرور: `admin`

**تاجر / Merchant:**
- اسم المستخدم: `merchant1`
- كلمة المرور: `merchant`

## هيكل المشروع / Project Structure

```
lib/
├── main.dart                 # نقطة البداية
├── models/                   # نماذج البيانات
│   ├── merchant.dart
│   ├── terminal.dart
│   ├── transaction.dart
│   └── user.dart
├── providers/                # إدارة الحالة
│   └── auth_provider.dart
├── screens/                  # الشاشات
│   ├── admin/
│   ├── auth/
│   └── merchant/
├── services/                 # الخدمات
│   ├── csv_service.dart
│   ├── data_service.dart
│   └── language_service.dart
├── utils/                    # الأدوات المساعدة
│   ├── app_theme.dart
│   ├── responsive.dart
│   └── web_utils.dart
└── widgets/                  # الويدجتات
    ├── chart_card.dart
    ├── stat_card.dart
    ├── desktop/
    └── mobile/
```

## الترخيص / License

هذا المشروع مرخص تحت [MIT License](LICENSE).

## المساهمة / Contributing

نرحب بمساهماتكم! يرجى فتح Issue أو Pull Request.

Contributions are welcome! Please feel free to submit a Pull Request.

## المؤلف / Author

تم تطوير هذا المشروع بواسطة فريق Cactus.

Developed by Cactus Team.

## الدعم / Support

للدعم والاستفسارات، يرجى فتح Issue في المستودع.

For support and inquiries, please open an Issue in the repository.
