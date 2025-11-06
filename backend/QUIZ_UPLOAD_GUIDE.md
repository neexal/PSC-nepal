# Quiz Upload Guide

This guide explains how to bulk upload quizzes using JSON files.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [JSON Format](#json-format)
3. [Upload Methods](#upload-methods)
4. [Field Descriptions](#field-descriptions)
5. [Examples](#examples)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

### Step 1: Create Your Quiz JSON File

Use the template in `quiz_data/sample_quiz_template.json` as a starting point.

### Step 2: Upload the Quiz

```bash
python manage.py import_quiz quiz_data/your_quiz.json
```

### Step 3: Verify in Admin

Visit http://localhost:8000/admin/quizzes/quiz/ to see your quiz!

---

## 📝 JSON Format

### Required Fields

```json
{
  "title": "Quiz Title",           // REQUIRED: Name of the quiz
  "topic": "Brief description",     // OPTIONAL: Shown in the app below title
  "category": "GK",                 // REQUIRED: GK, Nepali, English, or IT
  "subject": "General Knowledge",   // OPTIONAL: Subject name (auto-created)
  "duration": 20,                   // REQUIRED: Duration in minutes
  "questions": [                    // REQUIRED: Array of questions
    {
      "question_text": "Question?",   // REQUIRED: The question
      "options": ["A", "B", "C", "D"], // REQUIRED: Array of options (2+)
      "correct_option": 0,             // REQUIRED: Index of correct answer (0-3)
      "explanation": "Why correct",    // OPTIONAL: Explanation shown after
      "difficulty": "easy"             // OPTIONAL: easy, medium, hard (default: medium)
    }
  ]
}
```

---

## 📤 Upload Methods

### Method 1: Command Line (Recommended)

**Single file:**
```bash
python manage.py import_quiz quiz_data/my_quiz.json
```

**Multiple files:**
```bash
python manage.py import_quiz quiz_data/*.json
```

**Update existing quiz:**
```bash
python manage.py import_quiz quiz_data/my_quiz.json --update
```

### Method 2: Django Admin Panel

1. Go to http://localhost:8000/admin/
2. Click on **Quizzes**
3. Click **Add Quiz** button
4. Fill in the fields manually, OR
5. Use bulk import (future enhancement)

### Method 3: Python Script

Create a custom script:

```python
import json
from quizzes.models import Quiz, Question, Subject

with open('my_quiz.json') as f:
    data = json.load(f)

subject, _ = Subject.objects.get_or_create(name=data['subject'])

quiz = Quiz.objects.create(
    title=data['title'],
    topic=data.get('topic', ''),
    category=data['category'],
    total_questions=len(data['questions']),
    duration=data['duration'],
    subject=subject
)

for q in data['questions']:
    Question.objects.create(
        quiz=quiz,
        question_text=q['question_text'],
        options=q['options'],
        correct_option=q['correct_option'],
        explanation=q.get('explanation', ''),
        difficulty=q.get('difficulty', 'medium'),
        subject=subject
    )
```

---

## 📖 Field Descriptions

### Quiz Level

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `title` | string | ✅ Yes | Quiz name/title | "Nepal History Quiz" |
| `topic` | string | ❌ No | Brief description shown in app | "Ancient to Modern Nepal" |
| `category` | string | ✅ Yes | Must be: GK, Nepali, English, or IT | "GK" |
| `subject` | string | ❌ No | Subject name (auto-creates if new) | "General Knowledge" |
| `duration` | integer | ✅ Yes | Time limit in minutes | 20 |
| `questions` | array | ✅ Yes | List of question objects | [...] |

### Question Level

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `question_text` | string | ✅ Yes | The question | "What is the capital?" |
| `options` | array | ✅ Yes | List of 2-6 answer choices | ["A", "B", "C", "D"] |
| `correct_option` | integer | ✅ Yes | Index of correct answer (0-based) | 0 (for first option) |
| `explanation` | string | ❌ No | Why the answer is correct | "Because..." |
| `difficulty` | string | ❌ No | easy, medium, or hard | "medium" |

---

## 📚 Examples

### Example 1: Simple Quiz (Minimal)

```json
{
  "title": "Quick Math Quiz",
  "category": "GK",
  "duration": 10,
  "questions": [
    {
      "question_text": "What is 2 + 2?",
      "options": ["3", "4", "5", "6"],
      "correct_option": 1
    },
    {
      "question_text": "What is 5 × 3?",
      "options": ["12", "13", "14", "15"],
      "correct_option": 3
    }
  ]
}
```

### Example 2: Complete Quiz (All Fields)

```json
{
  "title": "Nepal Constitution Quiz",
  "topic": "Fundamental Rights and Duties",
  "category": "GK",
  "subject": "Constitution",
  "duration": 25,
  "questions": [
    {
      "question_text": "When was the Constitution of Nepal promulgated?",
      "options": [
        "September 20, 2015",
        "September 19, 2015",
        "January 23, 2007",
        "May 28, 2008"
      ],
      "correct_option": 0,
      "explanation": "The Constitution of Nepal 2015 was promulgated on September 20, 2015 (Ashoj 3, 2072 BS).",
      "difficulty": "medium"
    },
    {
      "question_text": "How many fundamental rights are guaranteed in the Constitution of Nepal 2015?",
      "options": ["25", "30", "31", "35"],
      "correct_option": 2,
      "explanation": "There are 31 fundamental rights listed in Articles 16 to 46 of the Constitution.",
      "difficulty": "hard"
    }
  ]
}
```

### Example 3: Nepali Language Quiz

```json
{
  "title": "नेपाली व्याकरण - मध्यम स्तर",
  "topic": "सन्धि र समास",
  "category": "Nepali",
  "subject": "Nepali",
  "duration": 20,
  "questions": [
    {
      "question_text": "'विद्या + आलय' को सन्धि के हुन्छ?",
      "options": ["विद्यालय", "विद्यआलय", "विदयालय", "बिद्यालय"],
      "correct_option": 0,
      "explanation": "आ + आ = आ भएर 'विद्यालय' हुन्छ। यो दीर्घ सन्धि हो।",
      "difficulty": "medium"
    }
  ]
}
```

---

## 🔍 Validation Rules

The import command automatically validates:

✅ Required fields are present  
✅ `questions` is a non-empty array  
✅ Each question has required fields  
✅ `options` array has at least 2 items  
✅ `correct_option` is a valid index (0 to options.length-1)  
✅ `category` matches allowed values  
✅ `difficulty` (if provided) matches allowed values  

---

## 🛠️ Troubleshooting

### Error: "no such table: quizzes_subject"

**Solution:** Run migrations first
```bash
python manage.py makemigrations
python manage.py migrate
```

### Error: "Missing required field: title"

**Solution:** Check your JSON has all required fields:
- `title`, `category`, `duration`, `questions`

### Error: "correct_option must be a valid index"

**Solution:** 
- `correct_option` should be 0-based index
- If you have 4 options, use 0, 1, 2, or 3
- NOT 1, 2, 3, or 4

**Wrong:**
```json
"options": ["A", "B", "C", "D"],
"correct_option": 4  ❌ Out of range!
```

**Correct:**
```json
"options": ["A", "B", "C", "D"],
"correct_option": 3  ✅ Last option (index 3)
```

### Error: "Invalid JSON"

**Solution:** Validate your JSON:
- Use https://jsonlint.com/
- Check for missing commas, quotes, brackets
- No trailing commas before closing `]` or `}`

### Quiz uploaded but not visible in app

**Solution:**
1. Check admin panel: http://localhost:8000/admin/quizzes/quiz/
2. Verify `category` field matches app categories
3. Restart frontend app if cached

---

## 📂 Organizing Your Quiz Files

Recommended structure:

```
backend/
└── quiz_data/
    ├── general_knowledge/
    │   ├── gk_set_1.json
    │   ├── gk_set_2.json
    │   └── nepal_history.json
    ├── nepali/
    │   ├── grammar_basic.json
    │   ├── grammar_advanced.json
    │   └── literature.json
    ├── english/
    │   ├── grammar.json
    │   └── vocabulary.json
    └── sample_quiz_template.json
```

Then import all at once:
```bash
python manage.py import_quiz quiz_data/*/*.json
```

---

## 🎯 Best Practices

1. **Start Small**: Test with 2-3 questions first
2. **Use Templates**: Copy `sample_quiz_template.json` for new quizzes
3. **Validate JSON**: Use online JSON validators before importing
4. **Add Explanations**: Helps students learn from mistakes
5. **Set Difficulty**: Use `easy`, `medium`, `hard` appropriately
6. **Test Topic Display**: Keep topics concise (< 50 characters)
7. **Backup**: Keep copies of your JSON files
8. **Version Control**: Commit JSON files to git

---

## 🔄 Updating Existing Quizzes

To update a quiz (replace all questions):

```bash
python manage.py import_quiz my_quiz.json --update
```

**Warning:** This deletes all old questions and creates new ones!

---

## 📊 Bulk Operations

### Import 100 quizzes at once:

```bash
python manage.py import_quiz quiz_data/**/*.json
```

### Check what will be imported (dry run):

```bash
python manage.py import_quiz --help
```

---

## 🆘 Need Help?

- Check examples in `quiz_data/` folder
- Review error messages carefully
- Test with `sample_quiz_template.json` first
- Ask in GitHub issues

---

## 📱 How Topic Appears in App

The `topic` field will be displayed in the Flutter app like this:

```
┌─────────────────────────────────────┐
│ 📚 Nepal History Quiz               │
│                                     │
│ Ancient to Modern Nepal             │ ← Topic shows here
│                                     │
│ 🕐 20 minutes │ 📝 15 questions    │
│                                     │
│          [START QUIZ]               │
└─────────────────────────────────────┘
```

---

**Happy Quiz Creating! 🎓**

For more information, see:
- [README.md](../README.md) - Project overview
- [QUICKSTART.md](../QUICKSTART.md) - Getting started
- Django admin: http://localhost:8000/admin/
