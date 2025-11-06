# 📚 Admin Panel Quiz Upload Guide

This guide shows you how to add quizzes directly from the Django admin panel (browser-based, no terminal needed).

---

## 🌐 Access Admin Panel

1. **Start your server:**
   ```bash
   python manage.py runserver
   ```

2. **Open browser and go to:**
   ```
   http://localhost:8000/admin/
   ```

3. **Login with:**
   - Username: `admin`
   - Password: `admin123`

---

## ✨ How to Add a Quiz (Step-by-Step)

### Step 1: Go to Quizzes

1. Click on **"Quizzes"** in the admin panel
2. Click **"ADD QUIZ"** button (top right)

### Step 2: Fill Basic Information

Fill in these fields:

| Field | What to Enter | Example |
|-------|---------------|---------|
| **Title** | Name of the quiz | "Nepal History Practice" |
| **Subject** | Select from dropdown | General Knowledge |
| **Category** | Select from dropdown | GK, Nepali, English, or IT |
| **Duration** | Time in minutes | 20 |

**Skip these fields (auto-generated):**
- ✅ Topic - Auto-generates as "Subject Quiz #1"
- ✅ Total questions - Auto-counts from JSON

### Step 3: Upload Questions (JSON)

1. **Expand** the "Bulk Upload Questions (Optional)" section (click to expand)

2. **Paste your JSON** in the text area:

```json
{
  "questions": [
    {
      "question_text": "What is the capital of Nepal?",
      "options": ["Kathmandu", "Pokhara", "Lalitpur", "Bhaktapur"],
      "correct_option": 0,
      "explanation": "Kathmandu is the capital city.",
      "difficulty": "easy"
    },
    {
      "question_text": "When did Nepal become a republic?",
      "options": ["2006", "2007", "2008", "2009"],
      "correct_option": 2,
      "explanation": "Nepal became a republic in 2008.",
      "difficulty": "medium"
    }
  ]
}
```

### Step 4: Save

Click **"SAVE"** button at the bottom.

**Done!** ✅ Your quiz is now live in the app!

---

## 📝 JSON Format (Simple)

### Minimum Required Format:

```json
{
  "questions": [
    {
      "question_text": "Your question here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_option": 0
    }
  ]
}
```

### Full Format (All Fields):

```json
{
  "questions": [
    {
      "question_text": "Your question here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_option": 0,
      "explanation": "Why this answer is correct (optional)",
      "difficulty": "medium"
    }
  ]
}
```

### Field Explanation:

| Field | Required? | Type | Values | Example |
|-------|-----------|------|--------|---------|
| `question_text` | ✅ Yes | Text | Any question | "What is 2+2?" |
| `options` | ✅ Yes | Array | 2-6 options | ["3", "4", "5"] |
| `correct_option` | ✅ Yes | Number | 0, 1, 2, 3... | 1 (for "4") |
| `explanation` | ❌ No | Text | Why correct | "Because..." |
| `difficulty` | ❌ No | Text | easy, medium, hard | "medium" |

---

## 💡 Examples

### Example 1: Simple Math Quiz (2 questions)

```json
{
  "questions": [
    {
      "question_text": "What is 5 + 3?",
      "options": ["6", "7", "8", "9"],
      "correct_option": 2
    },
    {
      "question_text": "What is 10 - 4?",
      "options": ["4", "5", "6", "7"],
      "correct_option": 2
    }
  ]
}
```

### Example 2: Nepal GK Quiz (5 questions)

```json
{
  "questions": [
    {
      "question_text": "What is the currency of Nepal?",
      "options": ["Rupee", "Dollar", "Rupiah", "Yen"],
      "correct_option": 0,
      "explanation": "The Nepali Rupee (NPR) is the currency of Nepal.",
      "difficulty": "easy"
    },
    {
      "question_text": "Which year did Mount Everest get climbed first?",
      "options": ["1950", "1951", "1952", "1953"],
      "correct_option": 3,
      "explanation": "Edmund Hillary and Tenzing Norgay first climbed Everest in 1953.",
      "difficulty": "medium"
    },
    {
      "question_text": "How many provinces are in Nepal?",
      "options": ["5", "6", "7", "8"],
      "correct_option": 2,
      "explanation": "Nepal has 7 provinces as per the 2015 constitution.",
      "difficulty": "easy"
    },
    {
      "question_text": "What is the national flower of Nepal?",
      "options": ["Lotus", "Rhododendron", "Rose", "Jasmine"],
      "correct_option": 1,
      "explanation": "Rhododendron (Lali Gurans) is the national flower.",
      "difficulty": "medium"
    },
    {
      "question_text": "Who was the first Prime Minister of Nepal?",
      "options": ["Bhimsen Thapa", "Jung Bahadur Rana", "BP Koirala", "Matrika Prasad Koirala"],
      "correct_option": 2,
      "explanation": "Bishweshwar Prasad Koirala was the first democratically elected PM in 1959.",
      "difficulty": "hard"
    }
  ]
}
```

### Example 3: Nepali Language Quiz

```json
{
  "questions": [
    {
      "question_text": "'घर' शब्दको बहुवचन के हुन्छ?",
      "options": ["घरहरू", "घरहरु", "घरहरुँ", "घरहरूँ"],
      "correct_option": 0,
      "explanation": "शुद्ध बहुवचन रूप 'घरहरू' हो।",
      "difficulty": "easy"
    },
    {
      "question_text": "कर्म कारकको विभक्ति चिन्ह के हो?",
      "options": ["ले", "लाई", "बाट", "मा"],
      "correct_option": 1,
      "explanation": "कर्म कारकको विभक्ति चिन्ह 'लाई' हो।",
      "difficulty": "medium"
    }
  ]
}
```

---

## ⚙️ Auto-Generation Features

### 1. Auto-Generated Topic

When you create a quiz, the topic is automatically generated based on the subject:

- **First quiz for "General Knowledge"** → Topic: "General Knowledge Quiz #1"
- **Second quiz for "General Knowledge"** → Topic: "General Knowledge Quiz #2"
- **First quiz for "Nepali"** → Topic: "Nepali Quiz #1"

You can edit the topic manually if you want something different!

### 2. Auto-Counted Questions

The system automatically counts your questions from the JSON and sets `total_questions`.

---

## ⚠️ Important: Index Starts at 0!

**Remember:** `correct_option` uses **0-based indexing**

### ❌ Wrong:
```json
{
  "options": ["A", "B", "C", "D"],
  "correct_option": 1
}
```
This selects **"B"**, not "A"!

### ✅ Correct:
```json
{
  "options": ["A", "B", "C", "D"],
  "correct_option": 0
}
```
This selects **"A"**

**Quick Reference:**
- 0 = First option
- 1 = Second option
- 2 = Third option
- 3 = Fourth option

---

## 🔄 Updating Existing Quiz

To update questions in an existing quiz:

1. Go to **Quizzes** in admin
2. Click on the quiz you want to edit
3. Scroll to **"Bulk Upload Questions"** section
4. Paste new JSON (this will **replace all old questions**)
5. Click **"SAVE"**

**Warning:** This deletes all previous questions for this quiz!

---

## ✅ Validation

The system automatically validates:

✅ JSON format is correct  
✅ "questions" array exists  
✅ Each question has required fields  
✅ Options array has at least 2 items  
✅ correct_option is a valid index  
✅ All data types are correct  

If there's an error, you'll see a clear error message telling you exactly what's wrong!

---

## 🛠️ Troubleshooting

### Error: "Invalid JSON format"

**Solution:** 
- Check for missing commas
- Check for missing quotes
- Validate at https://jsonlint.com/

**Common mistakes:**
```json
// ❌ Missing comma
{
  "questions": [
    {...}
    {...}  // Missing comma here!
  ]
}

// ✅ Correct
{
  "questions": [
    {...},
    {...}  // Comma added
  ]
}
```

### Error: "Question X: correct_option must be a valid index"

**Solution:** 
- Make sure `correct_option` is within the options range
- If you have 4 options, use 0, 1, 2, or 3

### Error: "JSON must contain a 'questions' array"

**Solution:**
Your JSON should start with `{"questions": [...]}`, not just `[...]`

---

## 📱 Verify in App

After saving:

1. **Refresh your Flutter app**
2. **Go to Quiz section**
3. **Select the category** you chose
4. **You'll see your quiz** with auto-generated topic!

---

## 🎯 Quick Workflow

**For adding 10 quizzes:**

1. Prepare 10 JSON files with questions
2. Open admin panel
3. For each quiz:
   - Click "Add Quiz"
   - Fill: Title, Subject, Category, Duration
   - Paste JSON
   - Click Save
4. Done! All 10 quizzes are live!

**Time:** ~2 minutes per quiz = 20 minutes for 10 quizzes

---

## 💾 Saving JSON Templates

**Tip:** Save your JSON templates for reuse:

1. Create a folder on your computer: `Quiz Templates/`
2. Save templates as:
   - `gk_template.json`
   - `nepali_template.json`
   - `english_template.json`
3. Copy-paste when creating new quizzes

---

## 🌐 For Cloud/Production

This system works perfectly on cloud:

1. **Deploy your backend** to Render/Railway
2. **Access admin panel** at: `https://your-app.onrender.com/admin/`
3. **Login** with your admin credentials
4. **Add quizzes** the same way!

No SSH or terminal access needed! 🎉

---

## 🔒 Security Note

**For production:**
1. Change admin password from default
2. Use strong password
3. Don't share admin credentials
4. Consider setting up staff users with limited permissions

---

## 📊 Summary

### ✅ What You Can Do:

- ✅ Add quizzes from browser (no terminal)
- ✅ Upload 10, 20, 30+ questions at once
- ✅ Auto-generate topic names
- ✅ Auto-count questions
- ✅ Validate JSON before saving
- ✅ Update existing quizzes
- ✅ Works on cloud/production
- ✅ User-friendly interface

### 🚀 Workflow:

1. Open admin panel
2. Click "Add Quiz"
3. Fill basic info (4 fields)
4. Paste JSON with questions
5. Click Save
6. Quiz is live in app!

---

## 📖 Additional Resources

- **Full JSON Guide:** See `QUIZ_UPLOAD_GUIDE.md`
- **Sample Templates:** See `quiz_data/` folder
- **Django Admin Docs:** https://docs.djangoproject.com/en/stable/ref/contrib/admin/

---

**You're all set! Start adding quizzes from the admin panel! 🎓✨**
