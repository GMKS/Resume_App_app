# Resume Layout Examples - Visual Implementation

## 📱 **How Layouts Look in the App**

### **Layout Selection in Customize Screen**

When users go to **Customize Resume → Design Settings**, they can select from these layout options:

```dart
// Layout Type Dropdown
DropdownButton<String>(
  value: settings.layoutType,
  items: [
    DropdownMenuItem(value: 'Single Column', child: Text('Single Column')),
    DropdownMenuItem(value: 'Two Column', child: Text('Two Column')),
    DropdownMenuItem(value: 'Grid', child: Text('Grid Layout')),
  ],
  onChanged: (value) => onSettingsChanged(
    settings.copyWith(layoutType: value),
  ),
)
```

---

## 📋 **Live Preview Examples**

### **1. Single Column Layout**

```
┌─────────────────────────────────────────┐
│ 📱 Resume Preview                       │
├─────────────────────────────────────────┤
│                                         │
│         SARAH JOHNSON                   │
│      Frontend Developer                 │
│                                         │
│ 📧 sarah@email.com │ 📞 (555) 123-4567  │
│ 🌐 linkedin.com/sarah │ 📍 New York, NY │
│                                         │
├─────────────────────────────────────────┤
│ PROFESSIONAL SUMMARY                    │
│ ════════════════════                    │
│                                         │
│ Creative frontend developer with 4+     │
│ years of experience building responsive │
│ web applications using React, Vue.js,   │
│ and modern JavaScript frameworks.       │
│                                         │
├─────────────────────────────────────────┤
│ WORK EXPERIENCE                         │
│ ════════════════════                    │
│                                         │
│ 🏢 Senior Frontend Developer             │
│ Tech Solutions Inc | 2022 - Present    │
│ New York, NY                            │
│                                         │
│ • Led UI/UX redesign increasing user   │
│   engagement by 35%                     │
│ • Implemented responsive design for    │
│   mobile-first approach                 │
│ • Mentored 3 junior developers         │
│                                         │
│ 🏢 Frontend Developer                   │
│ Digital Agency | 2020 - 2022           │
│ New York, NY                            │
│                                         │
│ • Built 15+ client websites using      │
│   React and Next.js                     │
│ • Optimized page load times by 40%     │
│                                         │
├─────────────────────────────────────────┤
│ SKILLS                                  │
│ ════════════════════                    │
│                                         │
│ [React] [Vue.js] [JavaScript]          │
│ [TypeScript] [HTML5] [CSS3]            │
│ [Sass] [Tailwind] [Node.js]            │
│                                         │
└─────────────────────────────────────────┘
```

### **2. Two Column Layout**

```
┌─────────────────────────────────────────────────────────────┐
│ 📱 Resume Preview                                           │
├─────────────────────────────────────────────────────────────┤
│                    SARAH JOHNSON                           │
│                 Frontend Developer                         │
│   📧 sarah@email.com │ 📞 (555) 123-4567 │ 📍 New York    │
│                                                             │
├─────────────────────┬───────────────────────────────────────┤
│ 📋 CONTACT           │ 📄 PROFESSIONAL SUMMARY              │
│ ═══════════          │ ════════════════════════             │
│                     │                                       │
│ 📧 sarah@email.com   │ Creative frontend developer with 4+  │
│ 📞 (555) 123-4567   │ years of experience building         │
│ 🌐 linkedin.com/... │ responsive web applications using    │
│ 📍 New York, NY     │ React, Vue.js, and modern JavaScript │
│                     │ frameworks. Passionate about         │
│ 🛠 SKILLS            │ creating intuitive user experiences  │
│ ═══════════          │ and optimizing performance.          │
│                     │                                       │
│ • React             │ 💼 WORK EXPERIENCE                    │
│ • Vue.js            │ ═══════════════════                   │
│ • JavaScript        │                                       │
│ • TypeScript        │ Senior Frontend Developer             │
│ • HTML5/CSS3        │ Tech Solutions Inc | 2022 - Present  │
│ • Sass/Tailwind     │ New York, NY                          │
│ • Node.js           │                                       │
│ • Git/GitHub        │ • Led UI/UX redesign increasing      │
│                     │   user engagement by 35%             │
│ 🎓 EDUCATION         │ • Implemented responsive design      │
│ ═══════════          │ • Mentored 3 junior developers       │
│                     │                                       │
│ B.S. Computer       │ Frontend Developer                    │
│ Science             │ Digital Agency | 2020 - 2022         │
│ NYU | 2016-2020     │ New York, NY                          │
│ GPA: 3.7/4.0        │                                       │
│                     │ • Built 15+ client websites          │
│ 📜 CERTIFICATIONS    │ • Optimized page load times by 40%   │
│ ═══════════          │ • Collaborated with design team      │
│                     │                                       │
│ • AWS Certified     │ 🚀 PROJECTS                           │
│ • React Developer   │ ═══════════════                       │
│ • Google Analytics  │                                       │
│                     │ E-Commerce Platform                   │
│ 🌍 LANGUAGES         │ Full-stack shopping site with        │
│ ═══════════          │ payment integration and inventory    │
│                     │ management                            │
│ • English (Native)  │                                       │
│ • Spanish (Fluent)  │ Portfolio Website                     │
│ • French (Basic)    │ Personal showcase built with Next.js │
│                     │ and deployed on Vercel               │
└─────────────────────┴───────────────────────────────────────┘
```

### **3. Grid Layout**

```
┌─────────────────────────────────────────────────────────────┐
│ 📱 Resume Preview                                           │
├─────────────────────────────────────────────────────────────┤
│                    SARAH JOHNSON                           │
│                 Frontend Developer                         │
│         📧 sarah@email.com │ 📞 (555) 123-4567             │
│                                                             │
│ PROFESSIONAL SUMMARY                                        │
│ ════════════════════════════════════════════════════       │
│ Creative frontend developer with 4+ years of experience... │
│                                                             │
├───────────────────┬───────────────────┬─────────────────────┤
│ 🛠 SKILLS          │ 💼 EXPERIENCE      │ 🎓 EDUCATION        │
│ ═══════════        │ ═══════════       │ ═══════════         │
│                   │                   │                     │
│ [React]           │ Senior Frontend   │ B.S. Computer       │
│ [Vue.js]          │ Developer         │ Science             │
│ [JavaScript]      │ Tech Solutions    │                     │
│ [TypeScript]      │ 2022 - Present   │ New York University │
│ [HTML5]           │                   │ 2016 - 2020        │
│ [CSS3]            │ • Led UI/UX       │ GPA: 3.7/4.0        │
│ [Sass]            │   redesign        │                     │
│ [Tailwind]        │ • 35% engagement  │ Relevant Courses:   │
│ [Node.js]         │   increase        │ • Web Development   │
│ [Git]             │ • Mentored 3 devs │ • Data Structures   │
│                   │                   │ • UI/UX Design      │
│                   │ Frontend Dev      │ • Database Systems  │
│                   │ Digital Agency    │                     │
│                   │ 2020 - 2022       │                     │
│                   │                   │                     │
│                   │ • Built 15+ sites │                     │
│                   │ • 40% performance │                     │
│                   │   improvement     │                     │
│                   │                   │                     │
├───────────────────┼───────────────────┼─────────────────────┤
│ 🚀 PROJECTS        │ 📜 CERTIFICATIONS │ 🌍 LANGUAGES        │
│ ═══════════        │ ═══════════       │ ═══════════         │
│                   │                   │                     │
│ E-Commerce        │ AWS Certified     │ English             │
│ Platform          │ Solutions         │ (Native)            │
│ Full-stack web    │ Architect         │                     │
│ application with  │ Issued: 2023      │ Spanish             │
│ payment processing│                   │ (Fluent)            │
│ and inventory     │ React Developer   │                     │
│ management        │ Certification     │ French              │
│                   │ Issued: 2022      │ (Basic)             │
│ Portfolio Website │                   │                     │
│ Personal showcase │ Google Analytics  │                     │
│ built with Next.js│ Individual        │                     │
│ and deployed on   │ Qualification     │                     │
│ Vercel platform   │ Issued: 2022      │                     │
│                   │                   │                     │
│ Task Manager App  │                   │                     │
│ React Native      │                   │                     │
│ mobile app with   │                   │                     │
│ real-time sync    │                   │                     │
│                   │                   │                     │
└───────────────────┴───────────────────┴─────────────────────┘
```

---

## 🎨 **Layout Features in Action**

### **Design Settings Panel**

```dart
Widget _buildLayoutSection() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layout Options', style: titleStyle),
          SizedBox(height: 12),

          // Layout Type Selection
          Row(
            children: [
              Icon(Icons.view_column, color: themeColor),
              SizedBox(width: 8),
              Text('Layout Type'),
            ],
          ),
          DropdownButton<String>(
            value: settings.layoutType,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 'Single Column',
                child: Row(
                  children: [
                    Icon(Icons.view_agenda),
                    SizedBox(width: 8),
                    Text('Single Column'),
                    Spacer(),
                    Text('Traditional', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Two Column',
                child: Row(
                  children: [
                    Icon(Icons.view_column),
                    SizedBox(width: 8),
                    Text('Two Column'),
                    Spacer(),
                    Text('Professional', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Grid',
                child: Row(
                  children: [
                    Icon(Icons.grid_view),
                    SizedBox(width: 8),
                    Text('Grid Layout'),
                    Spacer(),
                    Text('Modern', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(layoutType: value),
            ),
          ),

          SizedBox(height: 16),

          // Preview Button
          ElevatedButton.icon(
            onPressed: () => _showLayoutPreview(settings.layoutType),
            icon: Icon(Icons.preview),
            label: Text('Preview Layout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### **Interactive Preview**

```dart
void _showLayoutPreview(String layoutType) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$layoutType Preview'),
      content: Container(
        width: 300,
        height: 400,
        child: _buildMiniaturePreview(layoutType),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showFullPreview();
          },
          child: Text('Full Preview'),
        ),
      ],
    ),
  );
}
```

---

## 📱 **Real-World Usage**

### **When to Use Each Layout:**

**📋 Single Column:**

- Government/Traditional sectors
- ATS-heavy industries
- Simple, straightforward roles
- When content is limited

**📋 Two Column:**

- Tech industry
- Creative fields
- Professional services
- When you have diverse content

**📋 Grid Layout:**

- Design portfolios
- Modern startups
- Creative agencies
- Skill-heavy roles

### **Mobile Responsiveness:**

```dart
Widget _buildResponsiveLayout() {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        // Mobile: Force single column
        return _buildSingleColumnLayout();
      } else if (constraints.maxWidth < 900) {
        // Tablet: Maintain chosen layout but adjust spacing
        return _buildLayoutWithReducedSpacing();
      } else {
        // Desktop: Full layout as designed
        return _buildLayoutBasedContent();
      }
    },
  );
}
```

Each layout adapts automatically to different screen sizes while maintaining visual appeal and readability!
