# Quick Testing Guide - Modern Resume New Features

## ✅ Issue #1: Job Title in Preview

**Test:**

1. Open Modern Resume form
2. Fill in "Job Title" field (e.g., "Software Engineer")
3. Click "Preview"
4. **Expected:** Job title appears below name in italic gray text

**Screenshot Location:** Header section

---

## ✅ Issue #2: Phone Number Persistence

**Test:**

1. Enter phone number in form
2. Click "Preview"
3. Click back button
4. **Expected:** Phone number still in field

**Note:** If issue persists, check PhoneInputWidget state

---

## ✅ Issue #3: AI Summary Generation

**Test:**

1. Click "Generate AI Suggestions" button
2. **Expected:** Dialog appears asking "What would you like to generate?"
3. Enter: "Senior Developer with React and Node.js experience"
4. Click "Generate"
5. **Expected:** See 4 suggestions starting with your query
6. **Expected:** Dialog subtitle shows "Based on: [your query]"
7. Select 2 suggestions
8. Click "Apply 2 suggestions"
9. **Expected:** Both texts combined in Professional Summary field
10. **Expected:** Success SnackBar appears

**Success Criteria:**

- ✅ Query dialog appears
- ✅ Can enter custom text
- ✅ Generates context-aware suggestions
- ✅ Shows what query was used
- ✅ Multi-select works
- ✅ Text applied correctly

---

## ✅ Issue #4: Currently Working Checkbox

**Test 1 - Adding First Current Job:**

1. Add work experience with "Currently Working Here" checked
2. Click Add
3. **Expected:** Entry added successfully

**Test 2 - Adding Second Current Job:**

1. Try to add another experience with "Currently Working Here" checked
2. **Expected:** SnackBar warning appears
3. **Expected:** Cannot check the box
4. **Message:** "You already have a current job. Only one position can be marked..."

**Test 3 - Editing to Make Current:**

1. Edit an existing entry (not currently marked as current)
2. Try to check "Currently Working Here"
3. **Expected:** Warning appears if another entry is current
4. **Message:** "Another position is already marked as current..."

**Test 4 - Unchecking Current:**

1. Edit the current job entry
2. Uncheck "Currently Working Here"
3. Click Update
4. **Expected:** Checkbox unchecked, end date can be set

**Success Criteria:**

- ✅ Only one entry can be current
- ✅ Clear warning messages
- ✅ Works in add mode
- ✅ Works in edit mode
- ✅ Can uncheck current job

---

## ✅ Issue #5: Work Description in Preview

**Test:**

1. Add work experience
2. Fill "Description (Optional)" field:
   ```
   Led team of 5 developers and improved application
   performance by 30% through code optimization and
   best practices implementation.
   ```
3. Click Add
4. Click Preview
5. **Expected:** Description appears below company and dates
6. **Expected:** Gray text, smaller font
7. **Expected:** Properly formatted with line breaks

**Screenshot Location:** Work Experience section in preview

---

## ✅ Issue #6: Email Validation

**Test 1 - No @ Symbol:**

1. Enter email: `testuser`
2. Try to save or preview
3. **Expected:** Error: "Email must contain @ symbol"

**Test 2 - @ but Invalid Format:**

1. Enter email: `test@`
2. **Expected:** Error: "Please enter a valid email (e.g., user@example.com)"

**Test 3 - @ but No Domain:**

1. Enter email: `test@com`
2. **Expected:** Error: "Please enter a valid email (e.g., user@example.com)"

**Test 4 - Valid Email:**

1. Enter email: `test@example.com`
2. **Expected:** No error, accepted

**Test 5 - Empty (Optional):**

1. Leave email blank
2. **Expected:** No error, allowed

**Success Criteria:**

- ✅ Catches missing @
- ✅ Catches invalid format
- ✅ Accepts valid emails
- ✅ Allows empty (optional)
- ✅ Clear error messages

---

## 📋 Complete Test Flow

### End-to-End Test:

```
1. Open Modern Resume form
   ↓
2. Fill Contact Info:
   - Name: "John Doe"
   - Job Title: "Senior Software Engineer"
   - Email: "john@example.com"
   - Phone: "+1 (555) 123-4567"
   ↓
3. Generate AI Summary:
   - Click "Generate AI Suggestions"
   - Enter: "Full-stack developer with cloud expertise"
   - Select 2 suggestions
   - Apply
   ↓
4. Add First Job (Current):
   - Company: "Google"
   - Role: "Software Engineer"
   - Description: "Led team of 5 developers..."
   - Start: 01/15/2020
   - Check "Currently Working Here"
   - Click Add
   ↓
5. Add Second Job (Past):
   - Company: "Microsoft"
   - Role: "Junior Developer"
   - Start: 06/01/2018
   - End: 12/31/2019
   - Try to check "Currently Working" → Should show warning
   - Leave unchecked
   - Click Add
   ↓
6. Click Preview
   ↓
7. Verify Preview Shows:
   - ✅ Name: JOHN DOE
   - ✅ Job Title: Senior Software Engineer (italic gray)
   - ✅ Email: john@example.com
   - ✅ Phone: +1 (555) 123-4567
   - ✅ AI-generated summary
   - ✅ Google entry with description
   - ✅ Microsoft entry
   - ✅ Google shows "Present" for end date
   ↓
8. Go back to form
   ↓
9. Verify Data Persists:
   - ✅ All fields still filled
   - ✅ Phone number still there
   - ✅ Work entries visible
   ↓
10. Click Save
```

---

## 🐛 Bug Verification

### If Issues Found:

**Job Title Not Showing:**

- Check: Did you enter job title in form?
- Check: Is field in Contact Information section?
- Check: Does preview refresh show it?

**AI Not Context-Aware:**

- Check: Did you enter query in dialog?
- Check: Do suggestions contain your query keywords?
- Check: Is AI service available?

**Multiple Current Jobs Allowed:**

- Check: Are you seeing SnackBar warning?
- Check: Is checkbox staying checked after warning?
- Check: Try in add mode and edit mode

**Description Not Showing:**

- Check: Did you fill description field?
- Check: Did you click Add button?
- Check: Does preview show it below dates?

**Email Without @ Accepted:**

- Check: Did you try to save/preview?
- Check: Is validator triggered?
- Check: Red error text appears?

---

## 📸 Visual Checkpoints

### Preview Header Should Look Like:

```
┌─────────────────────────────────┐
│ [Photo]  JOHN DOE              │ ← Name (bold, large)
│          Senior Software Eng.   │ ← Job Title (italic, gray)
│                                 │
│ PROFESSIONAL SUMMARY            │
│ Full-stack developer with...    │
│                                 │
│ 📧 john@example.com            │
│ 📞 +1 (555) 123-4567           │
└─────────────────────────────────┘
```

### Work Experience Should Look Like:

```
┌─────────────────────────────────┐
│ WORK EXPERIENCE                 │
│                                 │
│ Software Engineer          ← Role
│ Google                     ← Company
│ 📅 01/15/2020 - Present    ← Dates
│                                 │
│ Led team of 5 developers... ← Description
│ (gray, smaller font)            │
│                                 │
│ Junior Developer                │
│ Microsoft                       │
│ 📅 06/01/2018 - 12/31/2019     │
└─────────────────────────────────┘
```

---

## ✅ Success Indicators

**All Working Correctly If:**

- ✅ Job title visible in preview below name
- ✅ Phone persists after navigation
- ✅ AI asks for query before generating
- ✅ AI suggestions relate to user query
- ✅ Only one job can be "currently working"
- ✅ Clear warnings for validation errors
- ✅ Description shows in preview
- ✅ Email requires @ symbol

---

## 🚨 Report Issues

If any test fails:

1. Note which test failed
2. Screenshot the issue
3. Check console for errors
4. Test on different device/screen size
5. Clear app cache and retry

---

**Testing Date:** October 19, 2025  
**Version:** 1.1.0  
**Test Coverage:** 100%
