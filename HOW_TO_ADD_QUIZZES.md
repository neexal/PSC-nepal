# 📚 How to Add Quizzes - Quick Guide

This guide shows you the **easiest way** to add new quizzes to your PSC Nepal app.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Create Your JSON File

Copy this template and save as `my_quiz.json` in `backend/quiz_data/` folder:

```json
{
  "title": "Your Quiz Title",
  "topic": "Brief description (optional)",
  "category": "GK",
  "subject": "General Knowledge",
  "duration": 20,
  "questions": [
    {
      "question_text": "Your question here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_option": 0,
      "explanation": "Why this answer is correct",
      "difficulty": "medium"
    }
  ]
}
```

### Step 2: Upload the Quiz

Open terminal in `backend` folder and run:

```bash
python manage.py import_quiz quiz_data/my_quiz.json
```

### Step 3: Verify

- **Backend**: Visit http://localhost:8000/admin/quizzes/quiz/
- **App**: Refresh the quiz list to see your new quiz!

**That's it!** ✅

---

## 📝 Important Fields Explained

### Quiz Information

| Field | Required? | Example | Notes |
|-------|-----------|---------|-------|
| **title** | ✅ Required | "Nepal History Quiz" | Shows as quiz name |
| **topic** | ❌ Optional | "Ancient to Modern Nepal" | Shows below title in app |
| **category** | ✅ Required | "GK" | Must be: GK, Nepali, English, or IT |
| **subject** | ❌ Optional | "General Knowledge" | Auto-created if new |
| **duration** | ✅ Required | 20 | Time in minutes |

### For Each Question

| Field | Required? | Example | Notes |
|-------|-----------|---------|-------|
| **question_text** | ✅ Required | "What is the capital?" | The question |
| **options** | ✅ Required | ["A", "B", "C", "D"] | 2-6 options |
| **correct_option** | ✅ Required | 0 | Index: 0 for A, 1 for B, etc. |
| **explanation** | ❌ Optional | "Because..." | Shows after submission |
| **difficulty** | ❌ Optional | "medium" | easy, medium, or hard |

---

## 💡 Examples

### Example 1: Basic Quiz

```json
{
  "title": "Quick Math Test",
  "category": "GK",
  "duration": 10,
  "questions": [
    {
      "question_text": "What is 2 + 2?",
      "options": ["3", "4", "5", "6"],
      "correct_option": 1
    },
    {
      "question_text": "What is 10 - 3?",
      "options": ["5", "6", "7", "8"],
      "correct_option": 2
    }
  ]
}
```

### Example 2: With Topic and Explanations

```json
{
  "title": "Nepal Geography Quiz",
  "topic": "Mountains and Rivers",
  "category": "GK",
  "subject": "Geography",
  "duration": 15,
  "questions": [
    {
      "question_text": "Which is the longest river in Nepal?",
      "options": ["Koshi", "Gandaki", "Karnali", "Rapti"],
      "correct_option": 2,
      "explanation": "Karnali River is the longest river in Nepal at 1,080 km.",
      "difficulty": "medium"
    },
    {
      "question_text": "How many peaks above 8000m are in Nepal?",
      "options": ["6", "7", "8", "9"],
      "correct_option": 2,
      "explanation": "Nepal has 8 peaks above 8000 meters.",
      "difficulty": "hard"
    }
  ]
}
```

---

## 🎯 Where Does "Topic" Show Up?

The `topic` field appears in the app like this:

```
┌─────────────────────────────────────┐
│  📚  Nepal History Quiz             │
│                                     │
│      Ancient to Modern Nepal    ← Topic
│                                     │
│  GK  │  15 questions  │  20 min    │
└─────────────────────────────────────┘
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Wrong: Using 1-based index
```json
"options": ["A", "B", "C", "D"],
"correct_option": 1  // This selects "B", not "A"!
```

### ✅ Correct: Using 0-based index
```json
"options": ["A", "B", "C", "D"],
"correct_option": 0  // This selects "A"
```

### ❌ Wrong: Invalid category
```json
"category": "History"  // Not allowed!
```

### ✅ Correct: Valid category
```json
"category": "GK"  // Use: GK, Nepali, English, or IT
```

---

## 🔄 Updating Existing Quiz

To replace all questions in a quiz:

```bash
python manage.py import_quiz quiz_data/my_quiz.json --update
```

**Warning**: This deletes old questions!

---

## 📂 Organizing Multiple Quizzes

Create folders by subject:

```
backend/quiz_data/
├── general_knowledge/
│   ├── gk_set_1.json
│   ├── nepal_history.json
│   └── world_geography.json
├── nepali/
│   ├── grammar_basic.json
│   └── literature.json
└── english/
    └── grammar.json
```

Import all at once:

```bash
python manage.py import_quiz quiz_data/*/*.json
```

---

## 🛠️ Troubleshooting

### Problem: "no such table: quizzes_quiz"

**Solution:**
```bash
python manage.py makemigrations
python manage.py migrate
```

### Problem: "Invalid JSON"

**Solution:**
- Check commas, brackets, quotes
- Use https://jsonlint.com/ to validate
- No trailing commas before `]` or `}`

### Problem: Quiz not showing in app

**Solutions:**
1. Check admin panel: http://localhost:8000/admin/
2. Restart Flutter app
3. Verify category matches: GK, Nepali, English, IT

---

## 📚 More Examples

Check these files in `backend/quiz_data/`:
- `sample_quiz_template.json` - Full example
- `nepali_grammar_quiz.json` - Nepali quiz
- `english_grammar_quiz.json` - English quiz

---

## 🔗 Full Documentation

For advanced usage, see:
- [QUIZ_UPLOAD_GUIDE.md](backend/QUIZ_UPLOAD_GUIDE.md) - Complete documentation
- [README.md](README.md) - Project overview

---

## ✅ Checklist Before Uploading

- [ ] JSON is valid (use jsonlint.com)
- [ ] All required fields present
- [ ] `correct_option` uses 0-based indexing
- [ ] Category is GK, Nepali, English, or IT
- [ ] At least 2 options per question
- [ ] Tested with small quiz first

---

## 🎉 You're Ready!

1. Create your JSON file
2. Run `python manage.py import_quiz your_file.json`
3. Check admin panel
4. Open app and see your quiz!

**Need help?** Check:
- Examples in `backend/quiz_data/`
- Full guide: `backend/QUIZ_UPLOAD_GUIDE.md`
- Open GitHub issue

---

**Happy quiz creating! 📖✨**
