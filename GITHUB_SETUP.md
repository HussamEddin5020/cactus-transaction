# دليل نشر المشروع على GitHub

## الخطوات المطلوبة

### 1. إنشاء حساب على GitHub (إذا لم يكن لديك حساب)
- اذهب إلى [GitHub.com](https://github.com)
- انقر على "Sign up" وأنشئ حساب جديد

### 2. تثبيت Git على جهازك (إذا لم يكن مثبتاً)
- تحميل Git من [git-scm.com](https://git-scm.com/download/win)
- اتبع خطوات التثبيت

### 3. إعداد Git على جهازك (للمرة الأولى فقط)
افتح PowerShell أو Command Prompt وأدخل:

```bash
git config --global user.name "اسمك"
git config --global user.email "بريدك@example.com"
```

### 4. إنشاء مستودع جديد على GitHub
1. سجل الدخول إلى GitHub
2. انقر على زر "+" في الزاوية العلوية اليمنى
3. اختر "New repository"
4. أدخل اسم المستودع: `cactus_dashboard_flutter_web`
5. اختر "Public" أو "Private" حسب رغبتك
6. **لا** تضع علامة على "Initialize this repository with a README"
7. انقر على "Create repository"

### 5. تهيئة المشروع وإضافة الملفات إلى Git

افتح PowerShell في مجلد المشروع وأدخل الأوامر التالية:

```bash
# الانتقال إلى مجلد المشروع
cd "C:\Users\AORUS\Desktop\cactus dash\cactus dashboard flutter web\cactus_dashboard_flutter_web"

# تهيئة مستودع Git
git init

# إضافة جميع الملفات
git add .

# إنشاء أول commit
git commit -m "Initial commit: Cactus Dashboard Flutter Web Application"

# إضافة المستودع البعيد (استبدل YOUR_USERNAME باسم المستخدم الخاص بك)
git remote add origin https://github.com/YOUR_USERNAME/cactus_dashboard_flutter_web.git

# رفع الملفات إلى GitHub
git branch -M main
git push -u origin main
```

### 6. إدخال بيانات المصادقة
عند رفع الملفات لأول مرة، سيطلب منك:
- اسم المستخدم على GitHub
- كلمة المرور (أو Personal Access Token)

**ملاحظة:** إذا طُلب منك Personal Access Token:
1. اذهب إلى GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. انقر على "Generate new token"
3. اختر الصلاحيات: `repo` (كامل)
4. انسخ الرمز واستخدمه ككلمة مرور

## الأوامر الأساسية لاحقاً

### عند إجراء تغييرات جديدة:

```bash
# رؤية الملفات المتغيرة
git status

# إضافة الملفات المتغيرة
git add .

# أو إضافة ملف محدد
git add path/to/file.dart

# إنشاء commit
git commit -m "وصف التغييرات"

# رفع التغييرات إلى GitHub
git push
```

### سحب آخر التحديثات:

```bash
git pull
```

### إنشاء فرع جديد:

```bash
git checkout -b feature/new-feature
git push -u origin feature/new-feature
```

## نصائح مهمة

1. **لا ترفع ملفات حساسة:**
   - كلمات المرور
   - مفاتيح API
   - ملفات `.env` المحتوية على معلومات حساسة

2. **استخدم رسائل commit واضحة:**
   - `git commit -m "إضافة فلتر الحالة للتحويلات"`
   - `git commit -m "تحسين تصميم القائمة الجانبية"`

3. **احفظ `.gitignore` محدثاً:**
   - الملف موجود بالفعل ويحتوي على الملفات التي يجب تجاهلها

4. **استخدم branches للميزات الكبيرة:**
   - `git checkout -b feature/new-feature`
   - اعمل التغييرات
   - `git push -u origin feature/new-feature`
   - افتح Pull Request على GitHub

## حل المشاكل الشائعة

### خطأ: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/cactus_dashboard_flutter_web.git
```

### خطأ: "failed to push some refs"
```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### نسيان إضافة ملفات
```bash
git add .
git commit --amend --no-edit
git push --force
```

## روابط مفيدة

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Flutter Documentation](https://docs.flutter.dev/)

