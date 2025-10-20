# Modern Resume Form - Visual Behavior Guide

## 🎯 Section Collapse Behavior

### ✅ NEW BEHAVIOR

```
┌─────────────────────────────────────┐
│ 📷 Profile Photo            [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📞 Contact Information      [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 💼 LinkedIn Profile         [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📝 Professional Summary     [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🔧 Skills                   [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 💼 Work Experience          [+]    │  ← ALWAYS EXPANDED
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Timeline Entry 1 [Edit] [Del]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Company: ____________               │
│ Role: _______________               │
│ Description: ________               │
│                                     │
│ [Start Date] [End Date]             │
│ ☐ Currently Working Here            │
│                                     │
│           [Add] or [Cancel][Update] │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🎓 Education                [+]    │  ← ALWAYS EXPANDED
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Timeline Entry 1 [Edit] [Del]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ University: __________              │
│ College: _____________              │
│ Degree: ______________              │
│                                     │
│ [Start Date] [End Date] (Optional)  │
│                                     │
│           [Add] or [Cancel][Update] │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ✓ Certifications            [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🏆 Achievements & Hobbies   [−]    │  ← Collapsed by default
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ➕ Additional Information   [−]    │  ← Collapsed by default
│                                     │  ← Auto-collapses after Add
└─────────────────────────────────────┘
```

---

## 🔄 Workflow Examples

### Example 1: Adding Multiple Work Experiences

```
Step 1: Form loads
┌─────────────────────────────────────┐
│ 💼 Work Experience          [+]    │  ← Already expanded!
│                                     │
│ Company: [________________]         │
│ Role: [___________________]         │
│ Description: [____________]         │
│                                     │
│ [Select Start Date]                 │
│ [Select End Date]                   │
│ ☐ Currently Working Here            │
│                                     │
│                          [Add]      │
└─────────────────────────────────────┘

Step 2: User fills in first job
┌─────────────────────────────────────┐
│ 💼 Work Experience          [+]    │
│                                     │
│ Company: [Google_________]          │
│ Role: [Software Engineer]           │
│ Description: [Led team...]          │
│                                     │
│ [01/15/2020]                        │
│ [06/30/2023]                        │
│ ☐ Currently Working Here            │
│                                     │
│                          [Add]      │
└─────────────────────────────────────┘

Step 3: Clicks Add button
┌─────────────────────────────────────┐
│ 💼 Work Experience          [+]    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Software Engineer               │ │
│ │ Google                          │ │
│ │ Led team of 5 developers...     │ │
│ │ 01/15/2020 - 06/30/2023         │ │
│ │                   [Edit] [Del]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Company: [________________]  ← CLEARED!
│ Role: [___________________]  ← CLEARED!
│ Description: [____________]  ← CLEARED!
│                                     │
│ [Select Start Date]          ← CLEARED!
│ [Select End Date]            ← CLEARED!
│ ☐ Currently Working Here     ← CLEARED!
│                                     │
│                          [Add]      │
└─────────────────────────────────────┘
         ↑
   STAYS EXPANDED! Ready for next entry!

Step 4: User adds second job immediately
(Section is still open, fields are clear, ready to go!)
```

---

### Example 2: Editing Work Experience

```
Step 1: Click Edit icon on entry
┌─────────────────────────────────────┐
│ 💼 Work Experience          [+]    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Software Engineer               │ │
│ │ Google                          │ │
│ │ Led team...                     │ │
│ │ 01/15/2020 - 06/30/2023         │ │
│ │             [📝Edit] [❌Del]    │ │ ← Click Edit
│ └─────────────────────────────────┘ │
│                                     │
│ Company: [________________]         │
│ Role: [___________________]         │
└─────────────────────────────────────┘

Step 2: Form fields populate with data
┌─────────────────────────────────────┐
│ 💼 Work Experience          [+]    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Software Engineer               │ │
│ │ Google                          │ │
│ │ Led team...                     │ │
│ │ 01/15/2020 - 06/30/2023         │ │
│ │                   [Edit] [Del]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Company: [Google_________]  ← LOADED
│ Role: [Software Engineer]   ← LOADED
│ Description: [Led team...]  ← LOADED
│ [01/15/2020]                ← LOADED
│ [06/30/2023]                ← LOADED
│                                     │
│                [Cancel]  [Update]   │ ← Different buttons!
└─────────────────────────────────────┘

Step 3: User modifies description
┌─────────────────────────────────────┐
│ Description: [Led team of 5 devs    │
│ and improved performance by 30%]    │ ← Modified!
│                                     │
│                [Cancel]  [Update]   │
└─────────────────────────────────────┘

Step 4: Clicks Update
✅ Entry updated in timeline
✅ Form fields cleared
✅ Buttons change back to [Add]
✅ Section stays expanded
```

---

### Example 3: Adding Additional Information

```
Step 1: Section collapsed by default
┌─────────────────────────────────────┐
│ ➕ Additional Information   [−]    │  ← Click to expand
└─────────────────────────────────────┘

Step 2: Expand and add info
┌─────────────────────────────────────┐
│ ➕ Additional Information   [+]    │  ← Now expanded
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Volunteer work at local shelter │ │  ← Previous entry
│ │                           [❌]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Additional Information:             │
│ ┌─────────────────────────────────┐ │
│ │ Contributed to open source      │ │
│ │ projects on GitHub              │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│                          [➕ Add]   │
└─────────────────────────────────────┘

Step 3: After clicking Add
┌─────────────────────────────────────┐
│ ➕ Additional Information   [−]    │  ← AUTO-COLLAPSED!
└─────────────────────────────────────┘

Step 4: Expand again to see entries
┌─────────────────────────────────────┐
│ ➕ Additional Information   [+]    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Volunteer work at local shelter │ │
│ │                           [❌]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Contributed to open source      │ │  ← New entry added!
│ │ projects on GitHub              │ │
│ │                           [❌]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Additional Information:             │
│ [_____________________________]     │  ← Field cleared
│                                     │
│                          [➕ Add]   │
└─────────────────────────────────────┘
```

---

## 📱 Button Visibility - Screen Sizes

### Small Screen (320px width)

```
┌─────────────────────────────────────┐
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │  [Choose Colorful Template] │   │  ← Full width button
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────┐    ┌──────────┐      │
│  │ Preview  │    │   Save   │      │  ← Equal width buttons
│  └──────────┘    └──────────┘      │
│                                     │
│  ─────────────── 48px ───────────── │  ← Extra padding
│                                     │
│  ─────────────── Safe ───────────── │  ← Visible above
│  ─────────────── Area ───────────── │     keyboard
└─────────────────────────────────────┘
```

### Large Screen (414px+ width)

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │                                       │  │
│  │    [Choose Colorful Template]        │  │
│  │                                       │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌─────────────────┐  ┌─────────────────┐  │
│  │    Preview      │  │      Save       │  │
│  └─────────────────┘  └─────────────────┘  │
│                                             │
│  ──────────────────── 48px ──────────────── │
│                                             │
│  ──────────────────── Safe ──────────────── │
│  ──────────────────── Area ──────────────── │
└─────────────────────────────────────────────┘
```

---

## 🎨 Preview Display - All Fields Visible

```
┌───────────────────────────────────────────────┐
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │  [Photo]  John Doe                      │  │
│  │           Software Engineer ← Job Title │  │
│  └─────────────────────────────────────────┘  │
│                                               │
│  📧 john@email.com    💼 linkedin.com/john   │
│  📞 (555) 123-4567     🌐 johndoe.com        │
│                                               │
│  ═══ Professional Summary ═══                │
│  Results-driven software engineer...         │
│                                               │
│  ═══ Work Experience ═══                     │
│  Software Engineer          01/20 - 06/23    │
│  Google                                       │
│  Led team of 5 developers and improved  ← Description
│  performance by 30% through optimization...   │
│                                               │
│  ═══ Education ═══                           │
│  Bachelor of Science            09/16-05/20  │
│  MIT                                          │
│                                               │
│  ═══ Skills ═══                              │
│  [Python] [Java] [React] [Docker]            │
│                                               │
│  ═══ Certifications ═══                      │
│  • AWS Certified Developer                   │
│  • Google Cloud Professional                 │
│                                               │
│  ═══ Additional Information ═══              │
│  • Volunteer work at local shelter      ← Custom
│  • Contributed to open source projects  ← Fields
│                                               │
└───────────────────────────────────────────────┘
```

---

## ✅ Quick Reference

### Sections That Auto-Collapse:

- Profile Photo
- Contact Information
- LinkedIn Profile
- Professional Summary
- Skills
- Certifications
- Achievements & Hobbies
- Additional Information ⚡

### Sections That Stay Expanded:

- Work Experience 🔓
- Education 🔓

### Buttons Available:

- **Add** - Add new entry (default state)
- **Update** - Save changes to existing entry (edit mode)
- **Cancel** - Discard changes and exit edit mode
- **Edit** (blue icon) - Load entry into form for editing
- **Delete** (red icon) - Remove entry from timeline
- **➕** - Add custom field to Additional Information

### Data Always Visible in Preview:

✅ Job Title (in header)  
✅ Work Experience Description  
✅ Additional Information (as bullets)  
✅ All 10 color themes  
✅ Profile Photo (when added)  
✅ Custom Fields (when added)

---

**Visual Guide Version:** 1.0.0  
**Last Updated:** October 18, 2025
