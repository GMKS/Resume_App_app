# Resume Layout Design Guide

This guide shows how different layout options should appear in the Resume Builder app.

## 📋 **Single Column Layout**

```
┌─────────────────────────────────────────┐
│                                         │
│           JOHN SMITH                    │
│        Software Engineer               │
│                                         │
│  📧 john@email.com  📞 (555) 123-4567   │
│  🌐 linkedin.com/in/johnsmith          │
│  📍 San Francisco, CA                   │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  PROFESSIONAL SUMMARY                   │
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬                  │
│                                         │
│  Experienced software engineer with     │
│  5+ years developing web applications   │
│  using React, Node.js, and Python.     │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  WORK EXPERIENCE                        │
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬                  │
│                                         │
│  Senior Software Engineer               │
│  Tech Corp | 2021 - Present            │
│  San Francisco, CA                      │
│                                         │
│  • Led development of microservices    │
│  • Improved system performance by 40%  │
│  • Mentored junior developers          │
│                                         │
│  Software Engineer                      │
│  StartupXYZ | 2019 - 2021              │
│  San Francisco, CA                      │
│                                         │
│  • Built responsive web applications   │
│  • Collaborated with cross-functional  │
│    teams                                │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  EDUCATION                              │
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬                  │
│                                         │
│  Bachelor of Computer Science           │
│  University of California | 2015-2019  │
│  GPA: 3.8/4.0                          │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  SKILLS                                 │
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬                  │
│                                         │
│  [JavaScript] [Python] [React]         │
│  [Node.js] [MongoDB] [AWS]             │
│  [Docker] [Kubernetes] [Git]           │
│                                         │
└─────────────────────────────────────────┘
```

**Characteristics:**

- ✅ **Traditional Format** - Most common and ATS-friendly
- ✅ **Full Width Content** - Maximum space utilization
- ✅ **Top-to-Bottom Flow** - Easy to read sequentially
- ✅ **Mobile Friendly** - Works well on narrow screens

---

## 📋 **Two Column Layout**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                      JOHN SMITH                            │
│                   Software Engineer                        │
│                                                             │
│    📧 john@email.com          📞 (555) 123-4567            │
│    🌐 linkedin.com/in/johnsmith   📍 San Francisco, CA     │
│                                                             │
├─────────────────────┬───────────────────────────────────────┤
│ LEFT SIDEBAR        │ MAIN CONTENT AREA                     │
│ (30% width)         │ (70% width)                           │
│                     │                                       │
│ CONTACT INFO        │ PROFESSIONAL SUMMARY                  │
│ ▬▬▬▬▬▬▬▬▬▬▬▬       │ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬        │
│                     │                                       │
│ 📧 john@email.com   │ Experienced software engineer with    │
│ 📞 (555) 123-4567   │ 5+ years developing web applications  │
│ 🌐 LinkedIn Profile │ using React, Node.js, and Python.    │
│ 📍 San Francisco    │ Passionate about building scalable   │
│                     │ solutions and leading teams.         │
│ SKILLS              │                                       │
│ ▬▬▬▬▬▬▬▬▬▬▬▬       │ WORK EXPERIENCE                       │
│                     │ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬        │
│ • JavaScript        │                                       │
│ • Python            │ Senior Software Engineer              │
│ • React             │ Tech Corp | 2021 - Present           │
│ • Node.js           │ San Francisco, CA                     │
│ • MongoDB           │                                       │
│ • AWS               │ • Led development of microservices   │
│ • Docker            │   architecture serving 1M+ users    │
│ • Kubernetes        │ • Improved system performance by 40% │
│                     │ • Mentored team of 5 junior devs     │
│ EDUCATION           │                                       │
│ ▬▬▬▬▬▬▬▬▬▬▬▬       │ Software Engineer                     │
│                     │ StartupXYZ | 2019 - 2021             │
│ B.S. Computer       │ San Francisco, CA                     │
│ Science             │                                       │
│ UC Berkeley         │ • Built responsive web applications  │
│ 2015-2019           │ • Collaborated with design team      │
│ GPA: 3.8/4.0        │ • Implemented CI/CD pipelines        │
│                     │                                       │
│ LANGUAGES           │ PROJECTS                              │
│ ▬▬▬▬▬▬▬▬▬▬▬▬       │ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬        │
│                     │                                       │
│ • English (Native)  │ E-Commerce Platform                   │
│ • Spanish (Fluent)  │ Full-stack web application with       │
│ • French (Basic)    │ payment processing and inventory      │
│                     │ management                            │
│ CERTIFICATIONS      │                                       │
│ ▬▬▬▬▬▬▬▬▬▬▬▬       │ Task Management App                   │
│                     │ React Native mobile app with         │
│ • AWS Certified     │ real-time collaboration features     │
│ • Scrum Master      │                                       │
│                     │                                       │
└─────────────────────┴───────────────────────────────────────┘
```

**Characteristics:**

- ✅ **Space Efficient** - More content in less vertical space
- ✅ **Visual Hierarchy** - Clear separation of sections
- ✅ **Professional Look** - Modern and clean appearance
- ✅ **Sidebar Advantage** - Quick access to key info

---

## 📋 **Grid Layout**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                      JOHN SMITH                            │
│                   Software Engineer                        │
│    📧 john@email.com  📞 (555) 123-4567  📍 San Francisco │
│                                                             │
├─────────────────────┬─────────────────────┬─────────────────┤
│ GRID CELL 1         │ GRID CELL 2         │ GRID CELL 3     │
│ (33% width)         │ (33% width)         │ (33% width)     │
│                     │                     │                 │
│ SKILLS              │ WORK EXPERIENCE     │ EDUCATION       │
│ ▬▬▬▬▬▬▬▬▬▬▬        │ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬    │ ▬▬▬▬▬▬▬▬▬▬▬    │
│                     │                     │                 │
│ [JavaScript]        │ Senior Engineer     │ B.S. Computer   │
│ [Python]            │ Tech Corp           │ Science         │
│ [React]             │ 2021 - Present     │                 │
│ [Node.js]           │                     │ UC Berkeley     │
│ [MongoDB]           │ • Led microservices│ 2015-2019       │
│ [AWS]               │ • 40% performance   │ GPA: 3.8/4.0    │
│ [Docker]            │   improvement       │                 │
│ [Kubernetes]        │ • Team leadership   │ Relevant        │
│                     │                     │ Coursework:     │
│                     │ Software Engineer   │ • Data Structures│
│                     │ StartupXYZ          │ • Algorithms    │
│                     │ 2019 - 2021        │ • Web Dev       │
│                     │                     │ • Database      │
│                     │ • Web applications  │   Systems       │
│                     │ • Cross-functional  │                 │
│                     │   collaboration     │                 │
│                     │                     │                 │
├─────────────────────┼─────────────────────┼─────────────────┤
│ GRID CELL 4         │ GRID CELL 5         │ GRID CELL 6     │
│                     │                     │                 │
│ PROJECTS            │ CERTIFICATIONS      │ LANGUAGES       │
│ ▬▬▬▬▬▬▬▬▬▬▬        │ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬    │ ▬▬▬▬▬▬▬▬▬▬▬    │
│                     │                     │                 │
│ E-Commerce Platform │ AWS Certified       │ English         │
│ Full-stack web app  │ Solutions Architect │ (Native)        │
│ with payment        │ Issued: 2023        │                 │
│ processing          │                     │ Spanish         │
│                     │ Certified Scrum     │ (Fluent)        │
│ Task Manager App    │ Master              │                 │
│ React Native mobile │ Issued: 2022        │ French          │
│ app with real-time  │                     │ (Basic)         │
│ collaboration       │ Google Cloud        │                 │
│                     │ Professional        │                 │
│ Portfolio Website   │ Issued: 2023        │                 │
│ Personal showcase   │                     │                 │
│ built with Next.js  │                     │                 │
│                     │                     │                 │
└─────────────────────┴─────────────────────┴─────────────────┘
```

**Characteristics:**

- ✅ **Modern Design** - Card-based layout system
- ✅ **Flexible Arrangement** - Sections can be reordered easily
- ✅ **Visual Appeal** - Clean, organized appearance
- ✅ **Responsive** - Adapts well to different screen sizes

---

## 🎨 **Layout Comparison**

| Feature               | Single Column | Two Column | Grid       |
| --------------------- | ------------- | ---------- | ---------- |
| **ATS Compatibility** | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐   | ⭐⭐⭐     |
| **Visual Appeal**     | ⭐⭐⭐        | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Content Density**   | ⭐⭐⭐        | ⭐⭐⭐⭐   | ⭐⭐⭐⭐⭐ |
| **Mobile Friendly**   | ⭐⭐⭐⭐⭐    | ⭐⭐⭐     | ⭐⭐⭐⭐   |
| **Print Quality**     | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   |

## 🔧 **Implementation Notes**

### **Single Column**

```dart
Widget _buildSingleColumnLayout() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader(),
      _buildSummary(),
      _buildExperience(),
      _buildEducation(),
      _buildSkills(),
      _buildProjects(),
    ],
  );
}
```

### **Two Column**

```dart
Widget _buildTwoColumnLayout() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left sidebar (30%)
      Expanded(
        flex: 3,
        child: Column(
          children: [
            _buildContactInfo(),
            _buildSkills(),
            _buildEducation(),
            _buildLanguages(),
          ],
        ),
      ),
      const SizedBox(width: 16),
      // Main content (70%)
      Expanded(
        flex: 7,
        child: Column(
          children: [
            _buildSummary(),
            _buildExperience(),
            _buildProjects(),
          ],
        ),
      ),
    ],
  );
}
```

### **Grid Layout**

```dart
Widget _buildGridLayout() {
  return Column(
    children: [
      _buildHeader(),
      const SizedBox(height: 16),
      // First row of grid
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildSkills()),
          const SizedBox(width: 12),
          Expanded(child: _buildExperience()),
          const SizedBox(width: 12),
          Expanded(child: _buildEducation()),
        ],
      ),
      const SizedBox(height: 16),
      // Second row of grid
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildProjects()),
          const SizedBox(width: 12),
          Expanded(child: _buildCertifications()),
          const SizedBox(width: 12),
          Expanded(child: _buildLanguages()),
        ],
      ),
    ],
  );
}
```

## 📋 **Recommended Usage**

### **Single Column - Best For:**

- Traditional industries (finance, law, government)
- ATS optimization priority
- Simple, straightforward presentations
- When content length is moderate

### **Two Column - Best For:**

- Tech industry positions
- Creative fields
- When you have varied content types
- Professional services

### **Grid Layout - Best For:**

- Design/creative portfolios
- Modern tech companies
- Startup environments
- When visual impact is important
- Showcasing diverse skills/projects

Each layout can be customized with different color themes, fonts, and section arrangements to match your personal brand and industry requirements.
